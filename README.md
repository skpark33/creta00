# creta00

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


####
####  When love and skil work together, expect a masterpiece
####  - John Ruskin - 
####

##
## skpark
## run way
## build directory configuration
flutter config --build-dir=../release/accTest0390  

#visual code 를 재기동한다.
## flutter run -d web-server --web-renderer html
flutter run -d chrome --web-renderer html

## build and release process
flutter build web --web-renderer html --release --base-href="/accTest0390/"

## first time after create repository
cd ../release/accTest0390/web
echo "# accTest0390" >> README.md
git init
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/skpark33/accTest0390.git
git push -u origin main

## GitHub 페이지에서 Settings 에서 GitHub pages 'click it out here' 를 누른다.
# Source choice 박스에서 main 을 고른뒤 save 를 눌러주면 웹페이지가 생기다.
# https://skpark33.github.io/accTest0390/

# for windows configuration

flutter config --enable-windows-desktop 
flutter create --platforms=windows . 
# you need to install Xcode or VisualStudio or gcc toolchains.
flutter run -d windows
flutter build windows





#npm install firebase
#npm install -g firebase-tools
#flutter build web --web-renderer html --release --base-href="/accTest0390/"

#############################################
### Flutter Web fireStore dataabse 사용하기
#############################################

1. Firebase 웹페이지에서 할일

-  console.firebase.google.com  엦 접속

* [+ project 추가]
* 프로젝트 이름 "Creta00"  [계속]
* 애널리틱스 사용설정 안함 [프로젝트 만들기]
* 앱에 Firebase 추가하여 시작하기
* [Web 아이콘버튼]
* 앱등록,  앱 닉네임
Creta00 
Firebase 호스팅 체크박스는 일단 건너뛰어 봄.
[앱등록]

#npm install firebase
#npm install -g firebase-tools

한 후에..

const firebaseConfig = {
  apiKey: "AIzaSyAy4Bvw7VBBklphDa9H1sbLZLLB9WE5Qk0",
  authDomain: "creta00-4c349.firebaseapp.com",
  projectId: "creta00-4c349",
  storageBucket: "creta00-4c349.appspot.com",
  messagingSenderId: "1022332856313",
  appId: "1:1022332856313:web:872be7560e0a039fb0bf28"
};

부분을 복사한다.



- 테이블 만들기

[콘솔로 이동]

좌측 메뉴 증에 [Firestore Database] 선택
[데이터베이스 만들기]

일단 [테스트모드에서 시작] 선택 (30일후 보안 정책을 결정해주면 됨)

[시작]

Cloud Firestore 위치  "asia-northeast3"  
[사용설정]

[+컬렉션 시작]

컬렉션 ID :  creta_user

데이터베이스를 만든다.
만들다가 오류가 나는 것은  Project home 으로 나갔다가 다시 들어와보면 만들어져 있다.



1.  yaml 에 다음을 추가


firebase_core: ^1.13.1
cloud_firestore: ^3.1.10
cloud_firestore_web: ^2.6.10

2. create_db.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creta00/common/util/logger.dart';

// 아까 복사한 부분을 이용해서 만든다.
class FirebaseConfig {
  static const String apiKey = "AIzaSyAy4Bvw7VBBklphDa9H1sbLZLLB9WE5Qk0";
  static const String authDomain = "creta00-4c349.firebaseapp.com";
  static const String projectId = "creta00-4c349";
  static const String storageBucket = "creta00-4c349.appspot.com";
  static const String messagingSenderId = "1022332856313";
  static const String appId = "1:1022332856313:web:872be7560e0a039fb0bf28";
}

class CretaDB {
  final List resultList = [];
  late CollectionReference collectionRef;

  CretaDB(String collectionId) {
    collectionRef = FirebaseFirestore.instance.collection(collectionId);
  }

  Future<List> getData(String? key) async {
    try {
      if (key != null) {
        DocumentSnapshot<Object?> result = await collectionRef.doc(key).get();
        if (result.data() != null) {
          resultList.add(result);
        }
      } else {
        await collectionRef.get().then((snapshot) {
          for (var result in snapshot.docs) {
            resultList.add(result);
          }
        });
      }
      return resultList;
    } catch (e) {
      logHolder.log("GET DB ERROR : $e");
      return resultList;
    }
  }
}


2.  main.dart 수정

import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //for firebase
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          appId: FirebaseConfig.appId,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          projectId: FirebaseConfig.projectId)); // for firebase
  runApp(const MyApp());
}

3  web/index.html 수정

body 바로 아래...

<body>

  <script> src="https://www.gstatic.com/firebasejs/8.6.1/firebase-app.js"</script>
  <script> src="https://www.gstatic.com/firebasejs/8.6.1/firebase-firestore.js"</script>







