# VitalSign Monitor

Real-time patient vital signs monitoring system with automated emergency alerting on the Stacks blockchain.

## Overview

VitalSign Monitor provides continuous health monitoring for patients using certified medical devices, with automated threshold monitoring and emergency response coordination.

## Features

- **Real-time Monitoring**: Continuous vital signs tracking from certified medical devices
- **Smart Thresholds**: Age-based and condition-specific vital sign threshold management
- **Emergency Alerts**: Automated emergency notifications when vital signs exceed safe ranges
- **Device Certification**: Secure authorization system for medical monitoring devices
- **Patient Profiles**: Comprehensive patient information and medical history tracking

## Smart Contract Functions

### Public Functions

- `register-patient`: Enroll patients in monitoring system with medical profile
- `authorize-device`: Certify medical devices for vital sign data collection
- `submit-vital-reading`: Record vital signs data from authorized monitoring devices
- `update-thresholds`: Modify patient-specific vital sign alert thresholds
- `acknowledge-alert`: Respond to and acknowledge emergency vital sign alerts

### Read-Only Functions

- `get-patient-profile`: Retrieve complete patient profile and monitoring status
- `get-vital-reading`: Access specific vital signs reading with device information
- `get-vital-thresholds`: View current patient-specific threshold configurations
- `get-device-info`: Verify medical device certification and authorization status
- `get-emergency-alert`: Access emergency alert details and response information
- `get-next-reading-id`: Get the next available reading identifier
- `get-next-alert-id`: Get the next available alert identifier

## Usage

Deploy the contract and register patients with authorized medical devices to begin continuous vital signs monitoring with automated emergency response.
