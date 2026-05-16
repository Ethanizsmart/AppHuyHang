# WasteApp

WasteApp là ứng dụng Flutter dùng để ghi nhận và quản lý hàng hủy trong nhà hàng/quán ăn. Ứng dụng hỗ trợ tính nhanh lượng nguyên liệu bị hao hụt dựa trên món ăn, công thức, batch nguyên liệu và số lượng cần hủy.

## Mục Tiêu

Dự án được xây dựng để giúp việc theo dõi hàng hủy rõ ràng và dễ kiểm soát hơn:

- Tìm kiếm món trong menu.
- Ghi nhận số lượng món bị hủy theo ngày.
- Nhập lý do hủy hàng.
- Tự động quy đổi món ăn thành danh sách nguyên liệu bị hao hụt.
- Quản lý công thức món, batch/sốt nền và kho nguyên liệu.
- Ghi nhận hủy nguyên liệu thủ công.
- Xem lại danh sách bản ghi hủy hàng.
- Xuất dữ liệu ra CSV hoặc Excel.

## Công Nghệ Sử Dụng

- Flutter / Dart
- Material UI
- `excel` để xuất file Excel
- `intl` để định dạng ngày tháng
- `path_provider`, `open_file` để lưu/mở file trên desktop và mobile
- `universal_html` để tải file trên web

## Cấu Trúc Chính

- `lib/main.dart`: chứa logic demo hiện tại, bao gồm model dữ liệu, công thức, giao diện và chức năng export.
- `web/`: cấu hình Flutter Web, manifest và icon.
- `pubspec.yaml`: khai báo dependencies của dự án.

## Ghi Chú

Đây là bản demo/tiện ích nội bộ. Dữ liệu mẫu và công thức hiện đang được khai báo trực tiếp trong code. Trong các phiên bản tiếp theo, có thể tách dữ liệu ra file hoặc database để dễ quản lý, cập nhật và mở rộng hơn.
