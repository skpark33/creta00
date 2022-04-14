import 'package:creta00/model/book.dart';
import 'package:flutter/material.dart';

import 'common/undo/undo.dart';
import 'common/util/logger.dart';
import 'constants/strings.dart';
import 'model/model_enums.dart';
import 'studio/pages/page_manager.dart';

BookManager? bookManagerHolder;

class BookManager extends ChangeNotifier {
  List<BookModel> bookList = [];
  BookModel? defaultBook;

  final List<String> _copyNameList = [];
  void addName(String name) {
    _copyNameList.add(name);
  }

  BookModel createDefaultBook({String userId = 'b49@sqisoft.com'}) {
    defaultBook = BookModel(MyStrings.initialName, userId,
        "'You could do it simple and plain'\nfrom [Sure thing] of Miguel.", "");
    return defaultBook!;
  }

  void setDefaultBook(BookModel book) {
    defaultBook = book;
  }

  void selectBook(List<BookModel> selectedBook) {
    bookList = selectedBook;
    logHolder.log("line 2");
    if (bookList.isEmpty) {
      logHolder.log("No data founded , first customer(2)", level: 7);
      createDefaultBook();
      bookList.add(defaultBook!);
    }
    for (BookModel model in bookList) {
      logHolder.log("mybook=${model.name.value}, ${model.updateTime}", level: 5);
    }
    defaultBook ??= bookList[0];
  }

  void setBookThumbnail(String path, ContentsType contentsType, double aspectRatio) {
    if (defaultBook == null) return;
    mychangeStack.startTrans();
    logHolder.log("setBookThumbnail $path, $contentsType", level: 5);
    defaultBook!.thumbnailUrl.set(path);
    defaultBook!.thumbnailType.set(contentsType);
    defaultBook!.thumbnailAspectRatio.set(aspectRatio);
    mychangeStack.endTrans();
    //DbActions.save(book.mid);
    // set 에서 이미 pushChanged 를 하고 있으므로, pushChanged 를 할 필요가 없다.
    // saveManagerHolder!.pushChanged(book.mid, 'setBookThumbnail');
  }

  bool makeCopy(String newName) {
    if (defaultBook!.name.value == newName) {
      return false;
    }
    // 중복체크
    if (!bookNameIsNew(newName)) {
      return false;
    }

    if (defaultBook != null) {
      BookModel newBook = defaultBook!.makeCopy(newName);
      // 사본 page 를 만들기만 할뿐, 현재의 page 를 대체하는 것은 아니다.
      pageManagerHolder!.makeCopy(defaultBook!.mid, newBook.mid);
      return true;
    }
    return false;
  }

  bool bookNameIsNew(String newName) {
    bool itsNew = true;
    for (BookModel model in bookList) {
      if (model.name.value == newName) {
        itsNew = false;
        break;
      }
    }
    for (String ele in _copyNameList) {
      if (ele == newName) {
        itsNew = false;
        break;
      }
    }
    return itsNew;
  }

  bool toggleReadOnly() {
    if (defaultBook != null) {
      defaultBook!.readOnly.set(!defaultBook!.readOnly.value);
      return true;
    }
    return false;
  }

  bool toggleIsPublic() {
    if (defaultBook != null) {
      defaultBook!.isPublic.set(!defaultBook!.isPublic.value);
      return true;
    }
    return false;
  }

  bool setName(String value) {
    if (defaultBook != null) {
      defaultBook!.name.set(value);
      notifyListeners();
      return true;
    }
    return false;
  }

  bool setDesc(String value) {
    if (defaultBook != null) {
      defaultBook!.description.set(value);
      return true;
    }
    return false;
  }

  String newNameMaker(String oldName) {
    int idx = oldName.lastIndexOf(RegExp("\\(\\d+\\)\$")); // 제일끝에 괄호로 둘러쌓인 숫자
    String prefix = idx > 0 ? oldName.substring(0, idx) : oldName;
    int postIndex = 1;
    bool itsNew = false;
    String newName = '';
    while (!itsNew) {
      newName = '$prefix($postIndex)';
      itsNew = bookNameIsNew(newName);
      postIndex++;
    }
    return newName;
  }
}
