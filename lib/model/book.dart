// import 'package:creta00/constants/strings.dart';
// import 'package:flutter/material.dart';
// import '../common/util/logger.dart';
// import '../common/undo/undo.dart';
//import '../constants/styles.dart';
//import 'package:creta00/model/users.dart';

import 'package:creta00/common/util/logger.dart';

import 'models.dart';
import 'model_enums.dart';
import '../common/undo/undo.dart';

// ignore: camel_case_types
class BookModel extends AbsModel {
  late UndoAble<String> name;
  late UndoAble<bool> isPublic;
  late UndoAble<BookType> bookType;
  late UndoAble<String> description;
  late UndoAble<bool> readOnly;
  late UndoAble<String> thumbnailUrl;
  late UndoAble<ContentsType> thumbnailType;
  late UndoAble<double> thumbnailAspectRatio;
  String userId;

  BookModel.createEmptyModel(String srcMid, this.userId) : super(type: ModelType.book, parent: '') {
    super.changeMid(srcMid);
    name = UndoAble<String>('', srcMid);
    thumbnailUrl = UndoAble<String>('', srcMid);
    thumbnailType = UndoAble<ContentsType>(ContentsType.free, srcMid);
    thumbnailAspectRatio = UndoAble<double>(1, srcMid);
    isPublic = UndoAble<bool>(false, srcMid);
    bookType = UndoAble<BookType>(BookType.signage, srcMid);
    readOnly = UndoAble<bool>(false, srcMid);
    description =
        UndoAble<String>("You could do it simple and plain\n from 'Sure thing' of Miguel", srcMid);
  }

  BookModel(nameStr, this.userId, String desc, String hash)
      : super(type: ModelType.book, parent: '') {
    name = UndoAble<String>(nameStr, mid);
    thumbnailUrl = UndoAble<String>('', mid);
    thumbnailType = UndoAble<ContentsType>(ContentsType.free, mid);
    thumbnailAspectRatio = UndoAble<double>(1, mid);
    isPublic = UndoAble<bool>(false, mid);
    bookType = UndoAble<BookType>(BookType.signage, mid);
    readOnly = UndoAble<bool>(false, mid);
    description =
        UndoAble<String>("You could do it simple and plain\n from 'Sure thing' of Miguel", mid);
    description.set(desc);
    hashTag.set(hash);
    save();
  }

  BookModel makeCopy(String newName) {
    BookModel newBook = BookModel(newName, userId, description.value, hashTag.value);
    newBook.bookType.set(bookType.value, save: false);
    newBook.isPublic.set(isPublic.value, save: false);
    newBook.thumbnailUrl.set(thumbnailUrl.value, save: false);
    newBook.thumbnailType.set(thumbnailType.value, save: false);
    newBook.thumbnailAspectRatio.set(thumbnailAspectRatio.value, save: false);
    logHolder.log('BookCopied(${newBook.mid}', level: 6);
    newBook.saveModel();
    return newBook;
  }

  @override
  void deserialize(Map<String, dynamic> map) {
    super.deserialize(map);
    name.set(map["name"], save: false);
    userId = map["userId"];
    isPublic.set(map["isPublic"], save: false);
    bookType.set(intToBookType(map["bookType"]), save: false);
    description.set(map["description"], save: false);
    thumbnailUrl.set(map["thumbnailUrl"], save: false);
    thumbnailType.set(intToContentsType(map["thumbnailType"] ?? 99), save: false);
    thumbnailAspectRatio.set((map["thumbnailAspectRatio"] ?? 1), save: false);
  }

  @override
  Map<String, dynamic> serialize() {
    return super.serialize()
      ..addEntries({
        "name": name.value,
        "userId": userId,
        "isPublic": isPublic.value,
        "bookType": bookTypeToInt(bookType.value),
        "description": description.value,
        "thumbnailUrl": thumbnailUrl.value,
        "thumbnailType": contentsTypeToInt(thumbnailType.value),
        "thumbnailAspectRatio": thumbnailAspectRatio.value,
      }.entries);
  }
}
