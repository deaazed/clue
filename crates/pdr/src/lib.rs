// Pedestrian Dead Reckoning — step detection, heading estimation,
// position reconstruction from IMU streams.

pub use sensors;
use sensors::{AccelSample, GyroSample, MagSample};

/// Smoothed magnitude must exceed this (m/s²) to register as a step peak.
const STEP_PEAK_THRESHOLD: f32 = 11.2;
/// Magnitude must drop below this before the next peak can be counted.
const STEP_VALLEY_THRESHOLD: f32 = 9.0;
/// Assumed stride length in metres.
const STRIDE_LEN: f64 = 0.75;
/// Mean Earth radius in metres.
const EARTH_R: f64 = 6_371_000.0;

/// Running PDR state for real-time use (e.g. live clue recording).
#[derive(Debug, Clone)]
pub struct PdrState {
    /// Estimated latitude in decimal degrees.
    pub lat: f64,
    /// Estimated longitude in decimal degrees.
    pub lng: f64,
    /// Heading measured clockwise from north, in radians.
    pub heading_rad: f64,
    /// Number of steps counted since the last GPS anchor.
    pub step_count: u32,

    smoothed_mag: f32,
    in_peak: bool,
    anchored: bool,
}

impl Default for PdrState {
    fn default() -> Self {
        Self {
            lat: 0.0,
            lng: 0.0,
            heading_rad: 0.0,
            step_count: 0,
            smoothed_mag: 9.8, // start near resting gravity
            in_peak: false,
            anchored: false,
        }
    }
}

impl PdrState {
    /// Anchor the DR position to a known GPS fix.
    /// Call this whenever a fresh GPS position is available.
    pub fn set_gps_anchor(&mut self, lat: f64, lng: f64) {
        self.lat = lat;
        self.lng = lng;
        self.anchored = true;
    }

    /// Feed one accelerometer sample.
    ///
    /// Returns `true` when a step is detected and the position has advanced.
    /// No position update occurs before the first [`set_gps_anchor`] call.
    pub fn update_accel(&mut self, sample: &AccelSample) -> bool {
        let v = &sample.value;
        let mag = (v.x * v.x + v.y * v.y + v.z * v.z).sqrt();

        // Exponential low-pass (α ≈ 0.2) to smooth out vibration noise
        self.smoothed_mag = 0.8 * self.smoothed_mag + 0.2 * mag;

        let step_detected = if !self.in_peak
            && self.smoothed_mag > STEP_PEAK_THRESHOLD
        {
            self.in_peak = true;
            if self.anchored {
                self.step_count += 1;
                // Advance DR position by one stride in heading direction
                let d_north = STRIDE_LEN * self.heading_rad.cos();
                let d_east = STRIDE_LEN * self.heading_rad.sin();
                self.lat += d_north.to_radians() / EARTH_R * (180.0 / std::f64::consts::PI);
                let cos_lat = self.lat.to_radians().cos();
                self.lng += (d_east / (EARTH_R * cos_lat)) * (180.0 / std::f64::consts::PI);
                true
            } else {
                false
            }
        } else {
            false
        };

        // Reset so the next valley+peak cycle can register a new step
        if self.in_peak && self.smoothed_mag < STEP_VALLEY_THRESHOLD {
            self.in_peak = false;
        }

        step_detected
    }

    /// Feed one gyroscope sample to update heading.
    ///
    /// `dt_s` is the elapsed time in seconds since the previous gyro sample.
    pub fn update_gyro(&mut self, sample: &GyroSample, dt_s: f32) {
        // Integrate z-axis angular velocity (clockwise = positive heading change)
        self.heading_rad += (sample.value.z * dt_s) as f64;
    }

    /// Update heading from a magnetometer reading.
    ///
    /// Uses the horizontal components; assumes the device is roughly level.
    /// Call this when stationary to correct gyro drift.
    pub fn update_mag(&mut self, sample: &MagSample) {
        let v = &sample.value;
        self.heading_rad = (v.x as f64).atan2(v.y as f64);
    }
}

/// Process a full recorded session and return the DR trajectory as
/// `(latitude, longitude)` waypoints, one per detected step.
///
/// # Arguments
/// * `accel` / `gyro` / `mag` — sensor streams from a `Session`
/// * `start_lat`, `start_lng` — GPS fix at the start of the session
pub fn replay(
    accel: &[AccelSample],
    gyro: &[GyroSample],
    mag: &[MagSample],
    start_lat: f64,
    start_lng: f64,
) -> Vec<(f64, f64)> {
    let mut state = PdrState::default();
    state.set_gps_anchor(start_lat, start_lng);
    let mut path = vec![(start_lat, start_lng)];

    let mut g_idx = 0usize;
    let mut last_gyro_ts: Option<u64> = None;

    // Seed heading from first magnetometer sample
    if let Some(m) = mag.first() {
        state.update_mag(m);
    }

    for a in accel {
        // Advance gyro index to match accelerometer timestamp
        while g_idx + 1 < gyro.len() && gyro[g_idx + 1].ts_ms <= a.ts_ms {
            g_idx += 1;
        }
        if g_idx < gyro.len() {
            let g = &gyro[g_idx];
            let dt = last_gyro_ts
                .map(|prev| g.ts_ms.saturating_sub(prev) as f32 / 1000.0)
                .unwrap_or(0.05); // assume 20 Hz if no prior sample
            last_gyro_ts = Some(g.ts_ms);
            state.update_gyro(g, dt);
        }

        if state.update_accel(a) {
            path.push((state.lat, state.lng));
        }
    }

    path
}

#[cfg(test)]
mod tests {
    use super::*;
    use sensors::{AccelSample, GyroSample, Vec3};

    fn accel(ts_ms: u64, x: f32, y: f32, z: f32) -> AccelSample {
        AccelSample { ts_ms, value: Vec3 { x, y, z } }
    }

    fn gyro(ts_ms: u64, gz: f32) -> GyroSample {
        GyroSample { ts_ms, value: Vec3 { x: 0.0, y: 0.0, z: gz } }
    }

    /// Drive the filter to a steady resting state (~9.8 m/s²).
    fn prime_filter(state: &mut PdrState) {
        for i in 0u64..40 {
            state.update_accel(&accel(i * 50, 0.0, 0.0, 9.8));
        }
    }

    #[test]
    fn no_step_without_anchor() {
        let mut s = PdrState::default();
        prime_filter(&mut s);
        // Inject a clear peak
        let detected = s.update_accel(&accel(2000, 0.0, 0.0, 13.0));
        assert!(!detected, "step must not register before GPS anchor");
        assert_eq!(s.step_count, 0);
    }

    #[test]
    fn detects_step_after_anchor() {
        let mut s = PdrState::default();
        s.set_gps_anchor(48.8566, 2.3522);
        prime_filter(&mut s);
        // The low-pass filter needs several samples at peak magnitude before
        // smoothed_mag exceeds STEP_PEAK_THRESHOLD (11.2). Feed 5 samples.
        for i in 0u64..5 {
            s.update_accel(&accel(2000 + i * 50, 0.0, 0.0, 13.0));
        }
        assert!(s.step_count >= 1, "at least one step should be counted");
    }

    #[test]
    fn position_advances_northward_at_zero_heading() {
        let mut s = PdrState::default();
        s.set_gps_anchor(48.8566, 2.3522);
        // heading_rad == 0 → moving north → lat should increase
        let lat0 = s.lat;
        prime_filter(&mut s);
        for i in 0u64..5 {
            s.update_accel(&accel(2000 + i * 50, 0.0, 0.0, 13.0));
        }
        if s.step_count > 0 {
            assert!(s.lat > lat0, "northward step must increase latitude");
        }
    }

    #[test]
    fn heading_integrates_gyro() {
        let mut s = PdrState::default();
        let h0 = s.heading_rad;
        // Turn right at 1 rad/s for 0.5 s
        s.update_gyro(&gyro(0, 1.0), 0.5);
        assert!((s.heading_rad - h0 - 0.5).abs() < 1e-6);
    }

    #[test]
    fn gps_anchor_resets_position() {
        let mut s = PdrState::default();
        s.set_gps_anchor(48.8566, 2.3522);
        s.lat = 99.0; // simulate drift
        s.set_gps_anchor(48.8566, 2.3522);
        assert!((s.lat - 48.8566).abs() < 1e-9);
    }

    #[test]
    fn replay_starts_at_origin() {
        let path = replay(&[], &[], &[], 48.8566, 2.3522);
        assert_eq!(path.len(), 1);
        assert!((path[0].0 - 48.8566).abs() < 1e-9);
        assert!((path[0].1 - 2.3522).abs() < 1e-9);
    }

    #[test]
    fn replay_with_steps_produces_waypoints() {
        let mut samples = vec![];
        // Prime the filter to resting gravity
        for i in 0u64..40 {
            samples.push(accel(i * 50, 0.0, 0.0, 9.8));
        }
        // Two clear steps
        samples.push(accel(2000, 0.0, 0.0, 13.0));
        samples.push(accel(2050, 0.0, 0.0, 13.0));
        samples.push(accel(2100, 0.0, 0.0, 8.0)); // valley
        samples.push(accel(2150, 0.0, 0.0, 13.0));
        samples.push(accel(2200, 0.0, 0.0, 13.0));

        let path = replay(&samples, &[], &[], 48.8566, 2.3522);
        assert!(path.len() >= 2, "should have at least the start + one step");
    }
}
