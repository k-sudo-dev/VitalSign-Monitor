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

(define-public (register-patient
  (patient-id principal)
  (age uint)
  (gender (string-ascii 10))
  (medical-conditions (string-ascii 200))
  (emergency-contact principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR_NOT_AUTHORIZED)
    (map-set patient-profiles
      { patient-id: patient-id }
      {
        age: age,
        gender: gender,
        medical-conditions: medical-conditions,
        emergency-contact: emergency-contact,
        monitoring-start: block-height,
        is-active: true
      }
    )
    (unwrap-panic (set-default-thresholds patient-id age))
    (ok true)
  )
)

(define-public (authorize-device
  (device-id (string-ascii 32))
  (manufacturer (string-ascii 50))
  (model (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR_NOT_AUTHORIZED)
    (map-set authorized-devices
      { device-id: device-id }
      {
        manufacturer: manufacturer,
        model: model,
        certified-at: block-height,
        is-active: true
      }
    )
    (ok true)
  )
)

(define-public (submit-vital-reading
  (patient-id principal)
  (device-id (string-ascii 32))
  (heart-rate uint)
  (bp-systolic uint)
  (bp-diastolic uint)
  (temperature uint)
  (oxygen-saturation uint)
  (reading-hash (buff 32)))
  (let ((reading-id (var-get next-reading-id))
        (device-data (unwrap! (map-get? authorized-devices { device-id: device-id }) ERR_INVALID_DEVICE))
        (patient-data (unwrap! (map-get? patient-profiles { patient-id: patient-id }) ERR_PATIENT_NOT_FOUND)))
    (asserts! (get is-active device-data) ERR_INVALID_DEVICE)
    (asserts! (get is-active patient-data) ERR_PATIENT_NOT_FOUND)
    (asserts! (and (> heart-rate u0) (< heart-rate u300)) ERR_INVALID_READING)
    (asserts! (and (> temperature u350) (< temperature u430)) ERR_INVALID_READING)
    (map-set vital-readings
      { patient-id: patient-id, reading-id: reading-id }
      {
        device-id: device-id,
        timestamp: block-height,
        heart-rate: heart-rate,
        blood-pressure-systolic: bp-systolic,
        blood-pressure-diastolic: bp-diastolic,
        temperature: temperature,
        oxygen-saturation: oxygen-saturation,
        reading-hash: reading-hash
      }
    )
    (var-set next-reading-id (+ reading-id u1))
    (unwrap-panic (check-vital-thresholds patient-id heart-rate bp-systolic temperature oxygen-saturation))
    (ok reading-id)
  )
)

(define-public (update-thresholds
  (patient-id principal)
  (max-heart-rate uint)
  (min-heart-rate uint)
  (max-bp-systolic uint)
  (min-bp-systolic uint)
  (max-temperature uint)
  (min-temperature uint)
  (min-oxygen-saturation uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR_NOT_AUTHORIZED)
    (map-set vital-thresholds
      { patient-id: patient-id }
      {
        max-heart-rate: max-heart-rate,
        min-heart-rate: min-heart-rate,
        max-bp-systolic: max-bp-systolic,
        min-bp-systolic: min-bp-systolic,
        max-temperature: max-temperature,
        min-temperature: min-temperature,
        min-oxygen-saturation: min-oxygen-saturation
      }
    )
    (ok true)
  )
)

(define-public (acknowledge-alert
  (patient-id principal)
  (alert-id uint)
  (response-time uint))
  (let ((alert-key { patient-id: patient-id, alert-id: alert-id })
        (alert-data (unwrap! (map-get? emergency-alerts alert-key) ERR_CLAIM_NOT_FOUND)))
    (asserts! (is-eq tx-sender contract-owner) ERR_NOT_AUTHORIZED)
    (map-set emergency-alerts
      alert-key
      (merge alert-data { status: "acknowledged", response-time: response-time })
    )
    (ok true)
  )
)

(define-private (set-default-thresholds (patient-id principal) (age uint))
  (let ((max-hr (if (< age u65) u180 u150))
        (min-hr u50))
    (map-set vital-thresholds
      { patient-id: patient-id }
      {
        max-heart-rate: max-hr,
        min-heart-rate: min-hr,
        max-bp-systolic: u140,
        min-bp-systolic: u90,
        max-temperature: u380,
        min-temperature: u360,
        min-oxygen-saturation: u95
      }
    )
    (ok true)
  )
)

(define-private (check-vital-thresholds
  (patient-id principal)
  (heart-rate uint)
  (bp-systolic uint)
  (temperature uint)
  (oxygen-saturation uint))
  (let ((thresholds (unwrap! (map-get? vital-thresholds { patient-id: patient-id }) ERR_PATIENT_NOT_FOUND))
        (alert-id (var-get next-alert-id)))
    (if (or
          (> heart-rate (get max-heart-rate thresholds))
          (< heart-rate (get min-heart-rate thresholds))
          (> bp-systolic (get max-bp-systolic thresholds))
          (> temperature (get max-temperature thresholds))
          (< oxygen-saturation (get min-oxygen-saturation thresholds)))
      (begin
        (map-set emergency-alerts
          { patient-id: patient-id, alert-id: alert-id }
          {
            alert-type: "vital-threshold-violation",
            triggered-at: block-height,
            vital-type: "multiple",
            critical-value: heart-rate,
            status: "active",
            response-time: u0
          }
        )
        (var-set next-alert-id (+ alert-id u1))
        (ok alert-id)
      )
      (ok u0)
    )
  )
)

(define-read-only (get-patient-profile (patient-id principal))
  (map-get? patient-profiles { patient-id: patient-id })
)

(define-read-only (get-vital-reading (patient-id principal) (reading-id uint))
  (map-get? vital-readings { patient-id: patient-id, reading-id: reading-id })
)

(define-read-only (get-vital-thresholds (patient-id principal))
  (map-get? vital-thresholds { patient-id: patient-id })
)

(define-read-only (get-device-info (device-id (string-ascii 32)))
  (map-get? authorized-devices { device-id: device-id })
)

(define-read-only (get-emergency-alert (patient-id principal) (alert-id uint))
  (map-get? emergency-alerts { patient-id: patient-id, alert-id: alert-id })
)

(define-read-only (get-next-reading-id)
  (var-get next-reading-id)
)

(define-read-only (get-next-alert-id)
  (var-get next-alert-id)
)