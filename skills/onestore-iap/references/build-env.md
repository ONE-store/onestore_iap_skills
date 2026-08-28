# 빌드 환경 — 자바(JDK) 문제

**연동 코드가 맞는데도 빌드가 안 되는 경우의 대부분이 JDK 설정이다.** 특히 IDE로 만든 프로젝트를
터미널에서 빌드할 때 갈린다 — IDE는 자기 내장 JDK를 쓰고, 터미널은 `JAVA_HOME`을 쓴다. **두 곳이 다른
자바를 가리키면 한쪽에서만 빌드된다.**

**답의 첫 줄은 "배치한 결제 코드 문제가 아닙니다"여야 한다.** 사용자는 방금 결제 코드를 넣고 빌드가
깨진 상태라 그쪽을 의심한다. 원인을 설명하기 전에 그 걱정부터 끊어야 매니저 클래스를 뒤지며 시간을
쓰지 않는다.

## 증상으로 가른다

| 오류 메시지에 나오는 것 | 무슨 뜻인가 |
|---|---|
| `Unsupported class file major version` | 빌드에 쓰는 자바가 **너무 최신**이라 Gradle이 못 읽는다 (major 61=JDK 17, 65=JDK 21) |
| `Android Gradle plugin requires Java …` | 빌드에 쓰는 자바가 **너무 낮다** |
| `JAVA_HOME is not set` · `Could not determine java version` | 터미널이 **자바를 못 찾는다** |
| `Invalid Gradle JDK configuration` | IDE의 Gradle JDK 항목이 **비었거나 없는 경로**를 가리킨다 |

**Kotlin·SDK 관련 오류가 아니라면 이 표부터 본다.** 배치한 매니저 클래스의 문법 오류와는 메시지가
확연히 다르다.

## 지금 무엇을 쓰고 있는지 확인한다

```bash
# 터미널이 쓰는 자바
java -version
echo $JAVA_HOME

# Gradle이 실제로 쓰는 자바 (이것이 진짜다)
./gradlew --version
```

`./gradlew --version` 출력의 `JVM` 줄이 **실제로 빌드에 쓰이는 자바**다. `java -version`과 달라도
이상한 것이 아니다 — Gradle은 `org.gradle.java.home`이나 IDE 설정을 먼저 본다.

## 고치는 방법 셋

**셋 다 "빌드에 쓰는 자바를 바꾸는 것"이다.** 아래 순서로 제시한다. **어느 것을 골랐는지 사용자에게
말한다.**

> [!warning] Gradle·AGP 버전을 올려서 맞추지 않는다
> 자바가 너무 최신이라 생긴 오류는 **Gradle을 올려서도** 풀린다. 그러나 그것은 **프로젝트 빌드 구성을
> 바꾸는 일**이고 AGP·Kotlin 버전까지 연쇄로 얽혀 결제와 무관한 곳이 깨질 수 있다. **결제 연동을
> 도우러 온 자리에서 할 일이 아니다.**
>
> 자바를 프로젝트가 요구하는 버전으로 맞추는 쪽이 되돌리기 쉽고 범위도 좁다. 사용자가 빌드 구성을
> 올리겠다고 하면 그때 **그것은 이 스킬의 범위 밖이라고 말하고** 넘긴다.

### 1. IDE 안에서 빌드한다

IDE 설정에서 Gradle JDK를 IDE 내장 자바로 맞춘다. 안드로이드 스튜디오는 JDK를 함께 설치하므로 보통
목록에 이미 있다.

터미널 빌드가 꼭 필요한 것이 아니면 이것으로 끝난다.

### 2. 프로젝트에 자바 경로를 박는다

프로젝트 루트 `gradle.properties`에 한 줄 넣는다. **그 프로젝트에서만** 적용되고 터미널·IDE 양쪽에
같이 걸린다.

```properties
org.gradle.java.home=/Applications/Android Studio.app/Contents/jbr/Contents/Home
```

경로는 설치 위치에 따라 다르므로 **실제로 있는지 확인하고 적는다.**

```bash
ls "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java"
```

> 이 줄은 **개인 환경에 묶인 설정**이다. 저장소를 여럿이 쓰면 경로가 다른 사람에게서 깨진다.
> 공유 저장소라면 `gradle.properties`가 아니라 3번(환경 변수)을 권한다.

### 3. 터미널의 `JAVA_HOME`을 바꾼다

셸 설정 파일에 넣는다. 그 기기의 모든 프로젝트에 걸린다.

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
```

넣은 뒤 새 터미널을 열거나 설정 파일을 다시 읽어야 적용된다. **`./gradlew --version`으로 바뀐 것을
확인하고 넘어간다.**

## 안내할 때 지킬 것

- **먼저 확인 명령을 주고 결과를 받는다.** 무엇을 쓰고 있는지 모르는 상태에서 경로를 고르면 틀린다
- **경로를 지어내지 않는다.** 위 경로는 흔한 위치일 뿐이다. `ls`로 확인된 것만 적는다
- **`gradle.properties`에 넣을 때는 공유 저장소인지 묻는다.** 개인 경로가 커밋되면 다른 사람 빌드가 깨진다
- 고친 뒤 **다시 빌드해 확인**하게 하고, 같은 오류가 남으면 이 문제가 아니었다고 말한다
