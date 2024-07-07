# 📺 노트 필기 어플리케이션 Alwrite

<br>

## 프로젝트 소개

- 다양한 필기 기능을 가지고 있는 노트 어플리케이션으로
- 기존 노트 어플리케이션에서 OCR를 활용한 텍스트 변환 기능과 녹음 요약 기능을 추가한 다용도 플랫폼입니다.
- 해당 레포지토리는 백엔드에 해당하는 레포지토리입니다.
<br>

## 팀원 구성

<div>

| **오하민** | **고수민** | **황선호** |
| :------: | :------: | :------: |
| [<img width="140px" src="https://avatars.githubusercontent.com/u/113972482?v=4" height=150 width=150> <br/> @ohamin26](https://github.com/ohamin26) | [<img width="140px" src="https://avatars.githubusercontent.com/u/80901129?v=4" height=150 width=150> <br/> @Gosuke716](https://github.com/Gosuke716) | [<img width="140px" src="https://avatars.githubusercontent.com/u/145864444?v=4" height=150 width=150> <br/> @ssssssssssun](https://github.com/ssssssssssun) |

</div>

<br>

## 1. 개발 환경

- Language && Framework : Dart, flutter, RiverPod
- 버전 및 이슈관리 : Github, Github Issues
  <br>

## 2. 채택한 개발 기술과 브랜치 전략

### Dart, flutter
 - 기획 시 멀티 플랫폼 배포를 목표로 하였고,
 - 플랫폼 간 위젯, 기능을 통일하기 위해 멀티 플랫폼 개발이 가능한 flutter를 선택하였습니다.
  
### Riverpod
- 이번 프로젝트에서 HookWidget을 이용하여 개발을 진행하였고, HookWidget에 특화되어 있는 상태관리 도구인 Riverpod를 채택하여 개발하였습니다.

### 브랜치 전략

- Git-flow를 채택하였으며, main, dev, feat로 구분하여 진행하였습니다.
  - **main** 배포용으로 최종적으로 적용할 기능만을 합쳤습니다.
  - **dev** 모든 기능을 합치고 개발과 테스트 단계에 사용하는 브랜치 입니다.
  - **Feat** 개발을 효율적으로 진행하기 위해 기능 단위로 브랜치을 생성하여 dev 브랜치에 합치는 방식으로 진행하였습니다.

<br>

## 3. 프로젝트 구조

```
├── README.md
├── .gitignore
├── alwrite.iml
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
├── linux
├── macos
├── test
├── web
├── windows
├── android
└── lib
     ├── Controller
     ├── Provider
     └── View
```


## 4. 개발 기간 및 작업 관리

### 개발 기간

- 전체 개발 기간 : 2024.05.28 ~ 2024.06.20


### 작업 관리

- Gihub를 통해 관리하였습니다.

## 5. 트러블 슈팅
- 기능 중 하나로 사용자가 펜으로 화면에 글을 쓰면 해당 글을 사용자가 지정한 폰트로 바꿔 다시 화면에 띄워주는 기능을 개발해야 했습니다.
- 해당 기능을 구현하기 위해서 여러 개의 위젯을 어플리케이션 실행 중 동적으로 생성, 삭제, 수정이 가능하도록 해야 했는데, flutter의 경우 생성된 위젯을 화면에 띄워주는 방식으로 동작하기 때문에 개발에 어려움이 있었습니다.
- 해당 이슈를 위젯을 관리하는 위젯 리스트를 만들어 처음 화면에는 비어 있는 위 리스트를 출력한 후 위젯을 추가해야 할 상황에 위젯을 만들어 위젯 리스트에 추가해주어 해당 위젯이 화면에 노출되도록 구현하여 해결하였습니다.
- 해당 이슈 관련하여 정리한 글입니다.([@post](https://ohamin26.tistory.com/23))
