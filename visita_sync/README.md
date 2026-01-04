# visita_sync

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


📋 สรุปโครงสร้างโปรเจคที่สมบูรณ์

Flutter Desktop Application ที่สมบูรณ์แล้วครับ ประกอบด้วย:

📁 โครงสร้างไฟล์ทั้งหมด

hospital_visit_manager/
├── lib/
│   ├── main.dart                          ✅ ไฟล์หลักของแอป
│   ├── config/
│   │   └── app_config.dart               ✅ จัดการ Config และ Encryption
│   ├── models/
│   │   ├── visit_model.dart              ✅ Model สำหรับข้อมูล Visit
│   │   └── database_settings.dart        ✅ Model สำหรับการตั้งค่า DB
│   ├── services/
│   │   ├── database_service.dart         ✅ เชื่อมต่อและจัดการ Database
│   │   ├── nhso_api_service.dart         ✅ เชื่อมต่อ NHSO API
│   │   ├── encryption_service.dart       ✅ เข้ารหัส Config
│   │   └── excel_export_service.dart     ✅ ส่งออก Excel
│   ├── providers/
│   │   └── visit_provider.dart           ✅ State Management
│   ├── screens/
│   │   ├── dashboard_screen.dart         ✅ หน้าหลัก Dashboard
│   │   └── settings_screen.dart          ✅ หน้าตั้งค่า
│   └── widgets/
│       ├── status_indicator.dart         ✅ แสดงสถานะการเชื่อมต่อ
│       ├── visit_data_table.dart         ✅ ตารางแสดงข้อมูล
│       └── filter_section.dart           ✅ ส่วนกรองข้อมูล
├── assets/
│   └── config/
├── pubspec.yaml                          ✅ Dependencies
├── README.md                             ✅ คำแนะนำการใช้งาน
├── database_schema.sql                   ✅ Schema สำหรับ MariaDB
├── build.sh                              ✅ Build Script (Linux/Mac)
└── build.ps1                             ✅ Build Script (Windows)