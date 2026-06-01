# pubspec.yaml에 추가할 패키지

터미널에서 아래 명령어로 추가하는 것을 추천합니다.

```powershell
flutter pub add http
flutter pub add url_launcher
```

직접 pubspec.yaml에 넣는다면 dependencies 아래에 추가합니다.

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.2
  url_launcher: ^6.3.1
```
