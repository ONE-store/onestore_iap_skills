# 원스토어 인앱결제 SDK — 레퍼런스

공식 개발 가이드(API V7 / SDK V21)와 공개 샘플 앱에서 확인한 사실이다. 대상은 `sdk-iap 21.04.00`,
`sdk-licensing 2.2.1`이다. **API 이름과 상수를 추측하지 않는다** — 필요한 것은 여기 다 있다. 전체
레퍼런스: <https://onestore-dev.gitbook.io/dev/tools/billing/v21/references>

인앱결제는 기기에 설치된 **원스토어 서비스(OSS) 앱을 거쳐** 처리된다. 앱 → SDK → 원스토어 서비스 →
결제 서버 순이다. 매니페스트 `<queries>` 선언과 업데이트·설치 유도 흐름이 필요한 이유가 이것이다.

**구글 플레이 결제와 다르다.** 이름이 비슷해 보여도 클래스가 다르다 — `PurchaseClient`(BillingClient
아님) · `IapResult`(BillingResult 아님) · `ProductDetail`(ProductDetails 아님). 플레이 결제 메서드
이름을 이 SDK에 대응시키지 않는다.

## 아티팩트

| 아티팩트 | 패키지 | 언제 필요한가 |
|---|---|---|
| `com.onestorecorp.sdk:sdk-iap:21.04.00` | `com.gaa.sdk.iap`, `com.gaa.sdk.base`, `com.gaa.sdk.auth` | 항상 (인앱결제) |
| `com.onestorecorp.sdk:sdk-licensing:2.2.1` | `com.onestore.extern.licensing` | **유료 앱만** (앱 라이선스 검증) |

둘 다 Maven Central에 있고, 위 버전이 공개된 최신 릴리스다. **버전을 지어내지 않는다.** 최신을
물어보면 `https://repo1.maven.org/maven2/com/onestorecorp/sdk/sdk-iap/maven-metadata.xml`을 확인한다.

## 핵심 클래스 (`com.gaa.sdk.iap`)

- `PurchaseClient` — 진입점. `PurchaseClient.newBuilder(context)`에
  `.setListener(PurchasesUpdatedListener)`와 `.setBase64PublicKey(String)`을 주고 만든다
- `IapResult` — 모든 호출의 결과. `isSuccess`, `responseCode`, `message`
- `PurchaseData` — 구매 한 건. `productId`, `purchaseToken`, `originalJson`, `signature`,
  `quantity`, `purchaseState`, `recurringState`, `isAcknowledged()`
- `ProductDetail` — 상품 정보. `productId`, `title`, `price`, `priceCurrencyCode`, `type`
- `ProductDetailsParams`, `PurchaseFlowParams`, `ConsumeParams`, `AcknowledgeParams`,
  `SubscriptionParams`, `RecurringProductParams` — 모두 `newBuilder()`로 만든다
- `PurchaseClientStateListener` — `onSetupFinished(IapResult)`, `onServiceDisconnected()`
- `PurchasesUpdatedListener` — `onPurchasesUpdated(IapResult, List<PurchaseData>?)`

관련: `com.gaa.sdk.base.Logger`(SDK 로그) · `com.gaa.sdk.base.StoreEnvironment`(설치 스토어 판별) ·
`com.gaa.sdk.auth.GaaSignInClient`(원스토어 로그인).

## PurchaseClient 메서드

```text
static Builder newBuilder(Context)
int      getConnectionState()
boolean  isReady()
IapResult isFeatureSupported(String)
void     startConnection(PurchaseClientStateListener)
void     endConnection()
IapResult launchPurchaseFlow(Activity, PurchaseFlowParams)
void     queryProductDetailsAsync(ProductDetailsParams, ProductDetailsListener)
void     queryPurchasesAsync(String productType, QueryPurchasesListener)
void     consumeAsync(ConsumeParams, ConsumeListener)
void     acknowledgeAsync(AcknowledgeParams, AcknowledgeListener)
void     launchLoginFlowAsync(Activity, IapResultListener)   // deprecated — 로그인은 GaaSignInClient 를 쓴다
void     launchUpdateOrInstallFlow(Activity, IapResultListener)
void     launchManageSubscription(Activity, SubscriptionParams)
void     manageRecurringProductAsync(RecurringProductParams, RecurringProductListener)   // v21에서 deprecated
void     getStoreInfoAsync(StoreInfoListener)
```

`launchPurchaseFlow`의 반환값은 **호출이 전달됐는지만** 알려준다. 실제 결제 결과는
`PurchasesUpdatedListener.onPurchasesUpdated`로 온다.

## 호출 순서

1. **먼저 연결한다.** `startConnection(listener)`을 호출하고 `onSetupFinished`가 `isSuccess`일 때만
   다음으로 간다.
2. **이후 모든 호출을 보호한다.** 원스토어 서비스와의 AIDL 연결은 명시적인 해제 없이도 끊길 수 있다
   — 기기 메모리 부족, OS의 백그라운드 정리, 앱이 백그라운드에서 돌아오는 과정. 그래서 모든 API
   호출은 `connectionState == PurchaseClient.ConnectionState.CONNECTED`를 확인하고 아니면 다시
   연결한 뒤 실행하는 함수를 거쳐야 한다. 공개 샘플도 이 방식을 쓰고 권장 패턴으로 명시한다.
   이 함수를 **연결 보장 함수**라고 부른다. **연결이 필요한 `PurchaseClient` 호출은 이것 없이 직접
   하지 않는다.**

   **예외 둘이 있고, 감싸면 오히려 깨진다.** `launchUpdateOrInstallFlow`는 원스토어 앱이 없거나
   낡아서 **연결이 성립하지 않는** 상태의 복구 경로이므로 감싸면 같은 오류로 떨어져 설치 화면이
   뜨지 않는다. `GaaSignInClient`(로그인)은 `PurchaseClient`가 아닌 별개 클라이언트라 연결 개념이
   없다.
3. `queryProductDetailsAsync(...)`로 상품 정보를 읽는다.
4. `launchPurchaseFlow(activity, params)`로 결제창을 띄운다.
5. **성공한 구매는 반드시 후처리한다** — 연동이 가장 자주 깨지는 자리다. **3일 안에 소비
   (`consumeAsync`) 또는 승인(`acknowledgeAsync`) 중 하나를 하지 않으면 미지급으로 판단해 자동
   환불된다.** 어느 쪽을 부르는지는 타입이 아니라 **상품의 역할**로 갈린다(다음 절).
   `PurchaseData.isAcknowledged()`로 이미 승인됐는지 알 수 있다.
6. 앱 시작이나 로그인 직후처럼 적절한 시점에 `queryPurchasesAsync(...)`로 조회해 **후처리가 끝나지
   않은 구매를 마무리한다.** 소비되지 않은 관리형 상품은 재구매가 되지 않아 사용자가 막힌다.
   **"적절한 시점"에 포그라운드 복귀가 포함된다** — 구매는 됐는데 소비·승인을 못 한 상태(강제 종료·
   네트워크 끊김·후처리 실패)는 앱을 새로 시작할 때만 정리되므로, 액티비티 `onResume`에서도 회수해야
   3일 규칙에 걸리지 않는다. **단 결제창에서 돌아오는 길에는 건너뛴다** — 결제 결과 콜백과 경합한다.
   **`INAPP`·`SUBS`·`AUTO`를 각각 조회한다** — `ALL`은 상품 정보 조회 전용이라 쓸 수 없고, 한
   타입이라도 빼면 그 상품의 최초 결제 승인이 유실됐을 때 복구할 곳이 없다. **`AUTO`(월정액)는 신규
   생성이 중단됐을 뿐이고, 이전에 만든 상품을 아직 파는 앱에는 남아 있다** — 없는 앱은 빈 목록이
   돌아올 뿐이므로 빼지 않는다.
   **타입을 모르는 구매를 건너뛰지 않는다.** 상품 조회가 실패했거나 조회 전에 구매가 들어오면 타입을
   알 수 없는데, 그때 아무것도 하지 않으면 3일 뒤 환불된다. **모르면 승인한다** — 소비성이었다면
   나중에 소비해 되돌릴 수 있지만, 환불된 것은 되돌릴 수 없다.
7. 종료 시 `endConnection()`.

## 상품 타입 (`PurchaseClient.ProductType`)

| 상수 | 값 | 의미 |
|---|---|---|
| `INAPP` | `"inapp"` | **관리형 상품** — 소비하기 전까지 재구매 불가 |
| `SUBS` | `"subscription"` | 구독형 상품 (SDK V21부터의 정기결제 타입) |
| `AUTO` | `"auto"` | 월정액 상품 — **deprecated, 신규 생성 불가.** 기존 상품은 계속 동작하므로 **미처리 구매 회수에서 빼지 않는다** |
| `ALL` | `"all"` | 상품 정보 조회에만 쓴다 — 구매 내역 조회에는 쓸 수 없다 |

### 관리형 상품이 곧 소비성 상품은 아니다

가장 자주 잘못 이해되는 부분이다. 관리형 상품(`INAPP`)은 **후처리 방식에 따라** 소비성·영구성·기간제가
된다.

| 의도한 역할 | 후처리 | 결과 |
|---|---|---|
| 소비성 (코인·물약 — 반복 구매) | 구매 직후 `consumeAsync`, 소비 완료 후 지급 | 재구매가 열린다 |
| **영구성** (광고 제거·프리미엄 해제) | **`acknowledgeAsync`만 — 절대 소비하지 않는다** | 계속 보유, 다시 구매 불가 |
| 기간제 | 기간이 끝난 뒤 소비 | 그 시점에 재구매가 열린다 |

그래서 **모든 `INAPP` 구매에 반사적으로 `consumeAsync`를 부르면 안 된다.** 어떤 상품이 소비성이고
어떤 것이 영구성인지 물어서 분기한다. 영구성 상품을 소비하면 사용자가 다시 구매할 수 있게 되어
조용히 깨진다.

구독(`SUBS`)은 **최초 결제에만** 구매 확인이 필요하고 갱신은 원스토어가 처리한다.
`acknowledgeAsync`는 관리형·월정액·구독 모두에 쓸 수 있다.

### 소비는 실패할 수 있다 — 중복 지급을 막는다

소비 요청은 실패할 수 있어서 같은 구매로 두 번 지급될 수 있다. **막는 방법과 서버 필요 여부는
"중복 지급 방지에도 서버가 필수는 아니다" 절이 원본이다.**

## 연결 상태 (`PurchaseClient.ConnectionState`)

`DISCONNECTED = 0` · `CONNECTING = 1` · `CONNECTED = 2` · `CLOSED = 3`

## 응답 코드 (`PurchaseClient.ResponseCode`)

서비스 결과:

| 코드 | 상수 | 의미 / 할 일 |
|---|---|---|
| 0 | `RESULT_OK` | 성공 |
| 1 | `RESULT_USER_CANCELED` | 사용자가 취소 — 오류가 아니다. 실패 안내를 띄우지 않는다. **레퍼런스 페이지에는 `USER_CANCELED`로 적혀 있지만 실제로 컴파일되는 상수는 `RESULT_USER_CANCELED`다.** 문서 표기대로 "고치지" 않는다 |
| 2 | `RESULT_SERVICE_UNAVAILABLE` | 단말 또는 서버 네트워크 오류 |
| 3 | `RESULT_BILLING_UNAVAILABLE` | 구매 처리 과정에서 오류 |
| 4 | `RESULT_ITEM_UNAVAILABLE` | 판매 중이 아니거나 구매할 수 없는 상품 — 상품 ID와 판매 상태를 확인 |
| 5 | `RESULT_DEVELOPER_ERROR` | 올바르지 않은 요청 (파라미터·서명) |
| 6 | `RESULT_ERROR` | 정의되지 않은 기타 오류 |
| 7 | `RESULT_ITEM_ALREADY_OWNED` | 이미 소유 중 — **소비성 상품이라면 소비 누락**이다. 영구성 상품·구독이면 정상 동작이므로 오류로 다루지 않는다. 받았을 때 미처리 구매를 회수하면 소비성은 재구매가 열린다 |
| 8 | `RESULT_ITEM_NOT_OWNED` | 소유하지 않은 상품 |
| 9 | `RESULT_FAIL` | 실패 |
| 10 | `RESULT_NEED_LOGIN` | 로그인 필요 → **`GaaSignInClient`** (아래 절) |
| 11 | `RESULT_NEED_UPDATE` | 원스토어 앱 설치·업데이트 필요 → `launchUpdateOrInstallFlow` |
| 12 | `RESULT_SECURITY_ERROR` | 보안 오류 |
| 13 | `RESULT_BLOCKED_APP` | 차단된 앱 |
| 14 | `RESULT_NOT_SUPPORT_SANDBOX` | 샌드박스 미지원 |
| 99999 | `RESULT_EMERGENCY_ERROR` | 긴급 오류 (서버 점검 등) |

SDK 내부에서 발생하는 오류:

| 코드 | 상수 |
|---|---|
| 1001 | `ERROR_DATA_PARSING` |
| 1002 | `ERROR_SIGNATURE_VERIFICATION` |
| 1003 | `ERROR_ILLEGAL_ARGUMENT` |
| 1004 | `ERROR_UNDEFINED_CODE` |
| 1005 | `ERROR_SIGNATURE_NOT_VALIDATION` |
| 1006 | `ERROR_UPDATE_OR_INSTALL` |
| 1007 | `ERROR_SERVICE_DISCONNECTED` |
| 1008 | `ERROR_FEATURE_NOT_SUPPORTED` |
| 1009 | `ERROR_SERVICE_TIMEOUT` |
| 1010 | `ERROR_CLIENT_NOT_ENABLED` |

`RESULT_NEED_LOGIN`과 `RESULT_NEED_UPDATE`는 오류 메시지가 아니라 **복구 흐름**이 필요한 둘이다.
반드시 따로 분기한다.

## 원스토어 로그인 (`com.gaa.sdk.auth.GaaSignInClient`)

`RESULT_NEED_LOGIN`(10)을 받으면 로그인 흐름을 띄운다. **`PurchaseClient.launchLoginFlowAsync`는
deprecated이므로 쓰지 않는다** — 컴파일 경고가 난다.

```text
static GaaSignInClient getClient(Activity)
void silentSignIn(SignInResultListener)          // 이미 로그인돼 있으면 백그라운드로 토큰 로그인
void launchSignInFlow(Activity, SignInResultListener)   // 로그인 화면 표시
```

결과는 `SignInResult`로 온다 — `isSuccessful` · `code` · `message`. **결제 응답 코드와는 체계가 다른
값이므로 `ResponseCode` 표로 해석하지 않는다.**

## 공개키

`setBase64PublicKey`에는 개발자센터 **공통정보 → 라이선스 관리**에서 확인한 라이선스 키를 넣는다.
`MII`로 시작하는 base64 문자열이다. 구매 서명 검증에
쓰인다.

**키를 넘기면 SDK가 서명을 검증한다.** 공개 샘플의 `AppSecurity` 주석이 "SDK 내부에도 `verifyPurchase`
부분이 동일하게 구현되어 있다"고 밝힌다. 즉 **앱단에서 할 수 있는 검증은 키를 넘기는 것으로 이미
이뤄진다** — 위조된 응답이나 가짜 결제 서비스는 서명이 맞지 않아 걸러진다. 매니저에 검증 코드를 따로
넣을 필요가 없다.

한 번 더 확인하고 싶으면 공개 샘플의 `AppSecurity.verifyPurchase(publicKey, originalJson, signature)`를
**앱 코드로 복사해** 쓴다. **SDK 공개 API가 아니다** — 공개 레퍼런스의 클래스 목록에 없고, 샘플이
제공하는 참고 구현이다. 같은 샘플의 `generatePayload()`로 developerPayload를 만들 수 있는데 **선택
사항**이다(샘플 주석: "발급하고 검증하는 것은 개발자의 선택이고 강제사항은 아니다").

## 결제 완결과 검증 — 셋을 섞지 않는다

**자주 뒤섞이는 세 가지다.** 이름이 다 "검증"처럼 들리지만 하는 일과 필수 여부가 다르다.

| 무엇 | 누가 | 필수인가 | 무엇을 위한 것인가 |
|---|---|---|---|
| **서명 검증** | **SDK** | 자동 | 위조된 구매 데이터·가짜 결제 서비스를 걸러낸다. 공개키를 넘기면 SDK가 한다 |
| **후처리** (`consume`·`acknowledge`) | 앱 ↔ 원스토어 | **필수** | **결제를 완결하는 절차다.** 앱이 "상품을 지급했다"고 원스토어에 알린다. **3일 안에 하지 않으면 미지급으로 판단해 자동 환불**된다 |
| **서버 대 서버 영수증 검증** | 앱 서버 → 원스토어 API | **선택(권장)** | 서버가 지급할 때 조작된 클라이언트를 거른다. **앱이 할 수 있는 일이 아니다** |

**필수인 것은 후처리 하나뿐이다.** 문서가 자동 환불로 강제하는 것도 이것이다 — "3일 이내에 구매를
확인(`acknowledge`) 또는 소비(`consume`)를 하지 않으면 사용자에게 상품이 지급되지 않았다고 판단되어
자동으로 환불됩니다."

**서버 검증을 필수로 말하지 않는다.** 공개 문서의 표현은 **권장**이고, 위치도 앱과 서버 둘 다 허용한다
— "개발사 앱이나 서버에서 서명 인증을 진행하는 것을 권장합니다." 서버가 없는 앱에 이것을 요구하면
없는 것을 요구하는 것이 된다.

### 중복 지급 방지에도 서버가 필수는 아니다

소비 요청은 실패할 수 있어서 같은 구매로 두 번 지급될 여지가 있다. **공개 문서가 방법 둘을 제시하고,
둘째는 서버가 없어도 된다.**

> 보안 백엔드 서버를 확인하여 각 구매 토큰이 사용되지 않았는지 확인해야 합니다. … **또는 자격을
> 부여하기 전에 성공적인 소비 응답을 받을 때까지 기다릴 수 있습니다.**

즉 **소비 성공 응답을 받은 뒤에 지급하면 서버 없이도 중복 지급을 막을 수 있다.** 배치되는 매니저가
이미 그 구조다 — 소비 콜백이 성공했을 때만 완료를 알린다. 서버가 있으면 구매 토큰 사용 여부를 서버에서
확인하는 쪽이 더 강하다.

### 서버 검증이 필요한 경우

**서버가 지급에 관여하는가**로 갈린다.

| 앱 구조 | 서버 검증 | 왜 |
|---|---|---|
| 서버가 계정에 상품을 지급한다 | **필요하다** | 조작된 클라이언트가 "샀다"고 말하는 것을 서버가 믿으면 무료 지급이 된다 |
| 앱이 로컬에서만 처리한다 (서버 없음) | **해당 없음** | 검증을 요청할 서버가 없다. SDK 서명 검증과 소비 성공 후 지급이 앱단에서 할 수 있는 전부다 |

공개 샘플이 서버 검증을 강하게 권하는 것은 사실이다 — "앱(클라이언트)에서는 어떠한 보안 로직도
안전할 수가 없다 … 서버로 영수증 검증해야 안전하다." 다만 그것은 **서버가 있는 구조를 전제한 권고**이고,
공식 가이드의 표현은 권장이다.

**원스토어의 결제 보증과는 다른 문제다.** 원스토어는 거래(결제 자체)를 보증하지만, 앱의 지급 로직이
조작되는 것까지 막아주지는 않는다. 반대로 SDK 서명 검증이 있으므로 **위조 응답은 이미 막힌다** —
남는 위험은 APK를 패치해 검증을 건너뛰는 것이고, 그것이 서버 지급 구조에서 서버 검증이 필요한 이유다.

**지급을 서버 왕복 때문에 미루지 않는다.** 구매 후 3일 안에 소비 또는 승인해야 하므로 후처리를 지연시킬
수 없다. 서버 검증을 하는 구조라면 검증과 후처리를 함께 진행하고, 실패 시 회수하는 쪽으로 설계한다.

### 키 보관

키는 가능하면 평문 소스에 두지 않는다 — 공개 문서가 "공개 키라 할지라도 앱 코드 안에 일반 문자열로
넣는 것은 안전한 방법이 아닙니다"라고 명시하고 XOR·난독화·서버 보관을 권한다. 공개 샘플 하나는 JNI로
키를 감춘다(`jni/public_keys.c`). 최소한 난독화는 적용한다.

## 로그 (`com.gaa.sdk.base.Logger`)

- `Logger.setLogEnable(Boolean)` — SDK 로그 on/off
- `Logger.setLogLevel(Int)` — `android.util.Log` 레벨
- 초기화 시점에 호출하고 **릴리즈 빌드에서는 끈다.**

## 설치 스토어 판별 (`com.gaa.sdk.base.StoreEnvironment`)

`StoreEnvironment.getStoreType(context)`로 앱이 원스토어를 통해 설치됐는지 알 수 있다.

| `StoreType` | 값 | 의미 |
|---|---|---|
| `UNKNOWN` | 0 | 알 수 없음 (APK 직접 설치, 출처 불명) |
| `ONESTORE` | 1 | 원스토어에서 설치됨 (또는 개발자 옵션 활성) |
| `VENDING` | 2 | 구글 플레이에서 설치됨 |
| `ETC` | 3 | 기타 스토어 |

## 앱 라이선스 검증 (유료 앱 전용, `com.onestore.extern.licensing`)

```text
static AppLicenseChecker get(Context, String base64PublicKey, LicenseCheckerListener)
void queryLicense()          // 캐시 허용
void strictQueryLicense()    // 항상 스토어에 확인
void destroy()               // 종료 시
```

`LicenseCheckerListener`: `granted(String license, String signature)` · `denied()` ·
`error(int code, String message)`.

무료 앱은 이 아티팩트가 아예 필요 없다.

## 매니페스트 요구사항

`<queries>`와 INTERNET 권한은 필수다. 선언 원문은 `manifest-queries.xml.txt`에 있다.

`<queries>`가 없으면 Android 11+ 패키지 가시성 제한 때문에 SDK가 기기의 원스토어 서비스를 찾지
못한다. **증상은 연결 오류로 나타나므로 매니페스트를 의심하기 어렵다** — 연결이 안 될 때 가장 먼저
확인할 항목이다.

## 테스트 (릴리즈 전)

- **샌드박스**는 가상 결제 환경이다. 결제 화면에서 성공·실패를 골라 그 결과를 받는다. **상용테스트**는
  실제 상용 환경에서 결제한다 — 취소하지 않으면 실제로 과금된다.
- **테스트용 원스토어 ID를 사전에 등록해야 한다**(개발자센터 → In-App 정보 → 결제 테스트). 등록하지
  않은 ID로는 샌드박스 테스트가 되지 않고, 상용테스트는 진짜 결제가 된다.
- **배포 전에 대상 OS에서 샌드박스 테스트를 최소 한 번은 해야 한다.**

## 공식 문서

- 인앱결제 가이드 (API V7 / SDK V21): <https://onestore-dev.gitbook.io/dev/tools/billing/v21>
  - 개요 `/ov` · 사전준비 `/pre` · 테스트·보안 `/test` · 구현 `/sdk`
  - API 레퍼런스 `/references` (클래스·빌더·상수 전체)
- 개발자 포털: <https://dev.onestore.net/dev/>
- 공개 샘플 앱: <https://github.com/ONE-store/onestore_iap_release>

문서 URL 뒤에 `.md`를 붙이면 마크다운으로 받을 수 있고, 루트의 `llms.txt`에 전체 페이지 목록이 있다.
