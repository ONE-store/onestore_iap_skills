# 의존성 추가

**앱 모듈** 빌드 파일에 추가한다. 프로젝트 구성에 맞는 방식을 고른다.

- `sdk-iap`은 항상 필요하다
- `sdk-licensing`은 **유료 앱만** 필요하다(앱 라이선스 검증). 인앱결제만 쓰는 무료 앱은 그 줄을 뺀다
- 아래 버전은 Maven Central에 공개된 최신 릴리스다. **버전을 지어내지 않는다.** 최신을 원하면
  `https://repo1.maven.org/maven2/com/onestorecorp/sdk/sdk-iap/maven-metadata.xml`을 먼저 확인한다

저장소는 `mavenCentral()`이다(SDK 저장소가 2026-04-01에 Maven Central로 이관됐다 — 오래된 안내는
다른 저장소를 가리킬 수 있다). 프로젝트 저장소 목록에 `google()`만 있으면 `mavenCentral()`을
추가한다 — 보통 `settings.gradle(.kts)`의 `dependencyResolutionManagement` 안이다.

## 방식 1 — Version Catalog을 쓰는 프로젝트 (`gradle/libs.versions.toml`이 있음)

카탈로그에 추가한다.

```toml
[versions]
onestore-iap = "21.04.00"
onestore-licensing = "2.2.1"

[libraries]
onestore-iap = { group = "com.onestorecorp.sdk", name = "sdk-iap", version.ref = "onestore-iap" }
onestore-licensing = { group = "com.onestorecorp.sdk", name = "sdk-licensing", version.ref = "onestore-licensing" }
```

앱 모듈의 `dependencies { }`에 추가한다.

```kotlin
// ONE Store IAP SDK — https://onestore-dev.gitbook.io/dev
implementation(libs.onestore.iap)
implementation(libs.onestore.licensing)
```

접근자 규칙에 주의한다 — 카탈로그 키 `onestore-iap`은 `libs.onestore.iap`으로 참조한다.

## 방식 2 — Kotlin DSL, 카탈로그 없음 (`build.gradle.kts`)

```kotlin
// ONE Store IAP SDK — https://onestore-dev.gitbook.io/dev
implementation("com.onestorecorp.sdk:sdk-iap:21.04.00")
implementation("com.onestorecorp.sdk:sdk-licensing:2.2.1")
```

## 방식 3 — Groovy DSL, 카탈로그 없음 (`build.gradle`)

```groovy
// ONE Store IAP SDK — https://onestore-dev.gitbook.io/dev
implementation 'com.onestorecorp.sdk:sdk-iap:21.04.00'
implementation 'com.onestorecorp.sdk:sdk-licensing:2.2.1'
```

## 빌드 설정

공개 샘플은 `compileSdk 35`, `minSdk 25`, Java·Kotlin 타깃 17로 빌드한다. **SDK가 그 값을 강제하는
것은 아니므로 프로젝트의 기존 `compileSdk`·`minSdk`·Java 타깃을 샘플에 맞춰 바꾸지 않는다.** 빌드가
실제로 실패할 때만 불일치를 보고한다.

## 추가한 뒤

1. Gradle 동기화가 필요하다고 알린다(안드로이드 스튜디오에 "Sync Now" 배너가 뜬다).
2. 앱 매니페스트에 `<queries>`가 있는지 확인한다 — `manifest-queries.xml.txt` 참고.
