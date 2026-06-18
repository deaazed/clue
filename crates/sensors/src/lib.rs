use serde::{Deserialize, Serialize};

// --- Primitives ---

/// Three-axis reading (accelerometer, gyroscope, magnetometer).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Vec3 {
    pub x: f32,
    pub y: f32,
    pub z: f32,
}

/// A single value with a session-relative timestamp in milliseconds.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Sample<T> {
    /// Milliseconds elapsed since the session started.
    pub ts_ms: u64,
    pub value: T,
}

// --- Sensor sample type aliases ---

/// Accelerometer sample — m/s²
pub type AccelSample = Sample<Vec3>;

/// Gyroscope sample — rad/s
pub type GyroSample = Sample<Vec3>;

/// Magnetometer sample — µT
pub type MagSample = Sample<Vec3>;

/// Barometer sample — hPa
pub type BaroSample = Sample<f32>;

// --- BLE ---

/// A single BLE device observed during a scan.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BleDevice {
    /// MAC address or UUID depending on platform.
    pub id: String,
    pub name: Option<String>,
    /// Signal strength in dBm.
    pub rssi: i16,
}

/// All devices seen in one scan sweep.
pub type BleSample = Sample<Vec<BleDevice>>;

// --- Session ---

/// A complete recorded session: one contiguous recording from start to stop.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Session {
    /// Unique session identifier (UUID v4).
    pub id: String,
    /// Wall-clock start time as Unix timestamp in milliseconds.
    pub started_at_ms: u64,
    pub accel: Vec<AccelSample>,
    pub gyro: Vec<GyroSample>,
    pub mag: Vec<MagSample>,
    // Not collected by Clue SL; optional so older clients can omit it
    #[serde(default)]
    pub baro: Vec<BaroSample>,
    pub ble: Vec<BleSample>,
}

impl Session {
    pub fn new(id: String, started_at_ms: u64) -> Self {
        Self {
            id,
            started_at_ms,
            accel: Vec::new(),
            gyro: Vec::new(),
            mag: Vec::new(),
            baro: Vec::new(),
            ble: Vec::new(),
        }
    }

    pub fn duration_ms(&self) -> u64 {
        let last = [
            self.accel.last().map(|s| s.ts_ms),
            self.gyro.last().map(|s| s.ts_ms),
            self.mag.last().map(|s| s.ts_ms),
            self.baro.last().map(|s| s.ts_ms),
            self.ble.last().map(|s| s.ts_ms),
        ]
        .into_iter()
        .flatten()
        .max()
        .unwrap_or(0);
        last
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_session_duration_is_zero() {
        let s = Session::new("test".into(), 0);
        assert_eq!(s.duration_ms(), 0);
    }

    #[test]
    fn session_duration_from_accel() {
        let mut s = Session::new("test".into(), 1_000_000);
        s.accel.push(AccelSample {
            ts_ms: 500,
            value: Vec3 { x: 0.0, y: 0.0, z: 9.8 },
        });
        assert_eq!(s.duration_ms(), 500);
    }

    #[test]
    fn session_duration_uses_latest_stream() {
        let mut s = Session::new("test".into(), 0);
        s.accel.push(AccelSample { ts_ms: 100, value: Vec3 { x: 0.0, y: 0.0, z: 9.8 } });
        s.gyro.push(GyroSample  { ts_ms: 200, value: Vec3 { x: 0.0, y: 0.0, z: 0.0 } });
        assert_eq!(s.duration_ms(), 200);
    }
}
