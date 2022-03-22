import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:creta00/common/util/logger.dart';

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
      logHolder.log("GET DB ERROR : $e", level: 7);
      return resultList;
    }
  }

  Future<void> setData(
    String? key,
    Object data,
  ) async {
    try {
      if (key != null) {
        await collectionRef.doc(key).set(data, SetOptions(merge: false));
        logHolder.log('$key saved');
      } else {
        await collectionRef.add(data);
        logHolder.log('$key created');
      }
      return;
    } catch (e) {
      logHolder.log("SET DB ERROR : $e", level: 7);
      return;
    }
  }
}
