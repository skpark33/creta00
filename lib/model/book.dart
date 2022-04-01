// import 'package:creta00/constants/strings.dart';
// import 'package:flutter/material.dart';
// import '../common/util/logger.dart';
// import '../common/undo/undo.dart';
//import '../constants/styles.dart';
//import 'package:creta00/model/users.dart';

import 'package:creta00/studio/pages/page_manager.dart';
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
  String userId;

  BookModel.copyEmpty(String srcMid, this.userId) : super(type: ModelType.book, parent: '') {
    super.changeMid(srcMid);
    name = UndoAble<String>('', srcMid);
    thumbnailUrl = UndoAble<String>('', srcMid);
    thumbnailType = UndoAble<ContentsType>(ContentsType.free, srcMid);
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
    isPublic = UndoAble<bool>(false, mid);
    bookType = UndoAble<BookType>(BookType.signage, mid);
    readOnly = UndoAble<bool>(false, mid);
    description =
        UndoAble<String>("You could do it simple and plain\n from 'Sure thing' of Miguel", mid);
    description.set(desc);
    hashTag.set(hash);
    save();
  }

  BookModel saveAs(String newName) {
    BookModel newBook = BookModel(newName, userId, description.value, hashTag.value);
    newBook.bookType = bookType;
    newBook.isPublic = isPublic;
    newBook.thumbnailUrl = thumbnailUrl;
    newBook.thumbnailType = thumbnailType;
    pageManagerHolder!.changeParent(mid, newBook.mid);
    newBook.save();
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
      }.entries);
  }
}
