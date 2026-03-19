# Student Manager - Firebase Backend (Nhiem vu 2.1)

Da trien khai cac chuc nang backend Firebase theo vai tro Leader + Backend:

- Firebase Auth: dang ky, dang nhap, dang xuat
- Cloud Firestore: CRUD sinh vien
- Phan quyen admin/user
- Service trung tam de UI call API

## Cau truc da tao

```text
lib/
	models/
		app_user_model.dart
		student_model.dart
	services/
		firebase_service.dart
	screens/
		auth/
			login_screen.dart
			register_screen.dart
		student/
			student_list_screen.dart
			add_student_screen.dart
			edit_student_screen.dart
	main.dart
```

## Huong dan cau hinh Firebase

1. Tao Firebase project tren Firebase Console.
2. Them app Android/iOS/Web vao Firebase project.
3. Chay lenh sau de gan Firebase vao Flutter:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

4. Dam bao da co file `google-services.json` (Android) va `GoogleService-Info.plist` (iOS) theo huong dan FlutterFire.
5. Chay:

```bash
flutter pub get
flutter run
```

## Day len GitHub khong lo key

Project da duoc cau hinh de KHONG track cac file nhay cam:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Neu file da tung bi track truoc do, chay mot lan:

```bash
git rm --cached lib/firebase_options.dart
git rm --cached android/app/google-services.json
git rm --cached ios/Runner/GoogleService-Info.plist
```

Sau do commit va push binh thuong. Moi thanh vien clone repo se tu chay lai:

```bash
flutterfire configure --project=<your-project-id>
```

## Phan quyen admin/user

- Khi dang ky moi, user duoc gan role mac dinh la `user`.
- Role duoc luu trong collection `users`:

```json
{
	"uid": "...",
	"email": "...",
	"displayName": "...",
	"role": "user"
}
```

- Admin co quyen them/sua/xoa sinh vien.
- User thuong chi xem danh sach.

De tao admin dau tien, cap nhat thu cong field `role = "admin"` cho mot user trong Firestore Console.

## Firestore collections

1. `users`
2. `students`

Document `students` gom:

```json
{
	"studentId": "SV001",
	"fullName": "Nguyen Van A",
	"className": "D21CQCN01",
	"department": "CNTT",
	"gpa": 3.45,
	"email": "a@school.edu",
	"createdAt": "Timestamp",
	"updatedAt": "Timestamp"
}
```

## Firestore security rules

Da them file `firestore.rules` trong root project.
Publish rules bang Firebase CLI:

```bash
firebase deploy --only firestore:rules
```
