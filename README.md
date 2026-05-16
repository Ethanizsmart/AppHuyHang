# WasteApp

WasteApp la ung dung Flutter dung de ghi nhan va quan ly hang huy trong nha hang/quan an. App ho tro tinh nhanh luong nguyen lieu bi hao hut dua tren mon an, cong thuc, batch nguyen lieu va so luong can huy.

## Muc tieu

Project nay duoc tao de giup viec theo doi hang huy ro rang hon:

- Tim kiem mon trong menu.
- Ghi nhan so luong mon bi huy theo ngay.
- Nhap ly do huy hang.
- Tu dong quy doi mon an thanh danh sach nguyen lieu bi hao.
- Quan ly cong thuc mon, batch/sot nen va kho nguyen lieu.
- Ghi nhan huy nguyen lieu thu cong.
- Xem lai danh sach ban ghi huy hang.
- Xuat du lieu ra CSV hoac Excel.

## Cong nghe su dung

- Flutter / Dart
- Material UI
- `excel` de xuat file Excel
- `intl` de dinh dang ngay thang
- `path_provider`, `open_file` cho luu/mo file tren desktop/mobile
- `universal_html` cho tai file tren web

## Cau truc chinh

- `lib/main.dart`: toan bo logic demo hien tai, gom model du lieu, cong thuc, UI va chuc nang export.
- `web/`: cau hinh Flutter Web, manifest va icon.
- `pubspec.yaml`: khai bao dependencies cua project.

## Cach chay local

```bash
flutter pub get
flutter run
```

Neu muon chay ban web:

```bash
flutter run -d chrome
```

## Build web

Build cho GitHub Pages can dat `base-href` theo ten repository.

Vi du repo hien tai la `AppHuyHang`:

```bash
flutter build web --release --base-href /AppHuyHang/
```

Neu doi repository thanh `WasteApp`:

```bash
flutter build web --release --base-href /WasteApp/
```

File build se nam trong:

```text
build/web
```

## Deploy GitHub Pages

Project co the deploy bang cach push noi dung `build/web` len nhanh `gh-pages`, sau do vao GitHub:

```text
Settings -> Pages -> Deploy from a branch -> gh-pages -> /root
```

Sau khi GitHub Pages build xong, app se co the truy cap qua URL dang:

```text
https://<username>.github.io/<repository-name>/
```

## Ghi chu

Day la ban demo/tien ich noi bo, du lieu mau va cong thuc dang duoc khai bao truc tiep trong code. Trong cac phien ban tiep theo, co the tach du lieu ra file/database de de quan ly va cap nhat hon.
