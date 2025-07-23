;; VitalSign Monitor - Patient Vital Signs Tracking
;; Version: 1.0.0

(define-constant ERR_NOT_AUTHORIZED (err u400))
(define-constant ERR_PATIENT_NOT_FOUND (err u401))
(define-constant ERR_INVALID_DEVICE (err u402))
(define-constant ERR_THRESHOLD_VIOLATION (err u403))
(define-constant ERR_INVALID_READING (err u404))

(define-map patient-profiles
  { patient-id: principal }
  {
    age: uint,
    gender: (string-ascii 10),
    medical-conditions: (string-ascii 200),
    emergency-contact: principal,
    monitoring-start: uint,
    is-active: bool
  }
)

(define-map vital-readings
  { patient-id: principal, reading-id: uint }
  {
    device-id: (string-ascii 32),
    timestamp: uint,
    heart-rate: uint,
    blood-pressure-systolic: uint,
    blood-pressure-diastolic: uint,
    temperature: uint,
    oxygen-saturation: uint,
    reading-hash: (buff 32)
  }
)

(define-map vital-thresholds
  { patient-id: principal }
  {
    max-heart-rate: uint,
    min-heart-rate: uint,
    max-bp-systolic: uint,
    min-bp-systolic: uint,
    max-temperature: uint,
    min-temperature: uint,
    min-oxygen-saturation: uint
  }
)

(define-map authorized-devices
  { device-id: (string-ascii 32) }
  { 
    manufacturer: (string-ascii 50),
    model: (string-ascii 50),
    certified-at: uint,
    is-active: bool
  }
)

(define-map emergency-alerts
  { patient-id: principal, alert-id: uint }
  {
    alert-type: (string-ascii 50),
    triggered-at: uint,
    vital-type: (string-ascii 30),
    critical-value: uint,
    status: (string-ascii 20),
    response-time: uint
  }
)

(define-data-var next-reading-id uint u1)
(define-data-var next-alert-id uint u1)
(define-constant contract-owner tx-sender)