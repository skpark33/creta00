enum UserType {
  superAdmin,
  customerAdmin,
  siteAdimin,
}

enum ModelType { none, book, page, acc, contents }

int typeToInt(ModelType type) {
  switch (type) {
    case ModelType.none:
      return 0;
    case ModelType.book:
      return 1;
    case ModelType.page:
      return 2;
    case ModelType.acc:
      return 3;
    case ModelType.contents:
      return 4;
  }
}

ModelType intToType(int t) {
  switch (t) {
    case 0:
      return ModelType.none;
    case 1:
      return ModelType.book;
    case 2:
      return ModelType.page;
    case 3:
      return ModelType.acc;
    case 4:
      return ModelType.contents;
    default:
      return ModelType.none;
  }
}

enum BookType {
  signage,
  electricBoard,
  presentaion,
  nft,
}

int bookTypeToInt(BookType value) {
  switch (value) {
    case BookType.signage:
      return 0;
    case BookType.electricBoard:
      return 1;
    case BookType.presentaion:
      return 2;
    case BookType.nft:
      return 3;
  }
}

BookType intToBookType(int t) {
  switch (t) {
    case 0:
      return BookType.signage;
    case 1:
      return BookType.electricBoard;
    case 2:
      return BookType.presentaion;
    case 3:
      return BookType.nft;
    default:
      return BookType.signage;
  }
}

enum ContentsType {
  video,
  image,
  text,
  sheet,
  youtube,
  free,
}

int contentsTypeToInt(ContentsType value) {
  switch (value) {
    case ContentsType.video:
      return 0;
    case ContentsType.image:
      return 1;
    case ContentsType.text:
      return 2;
    case ContentsType.sheet:
      return 3;
    case ContentsType.youtube:
      return 4;
    case ContentsType.free:
      return 99;
  }
}

ContentsType intToContentsType(int t) {
  switch (t) {
    case 0:
      return ContentsType.video;
    case 1:
      return ContentsType.image;
    case 2:
      return ContentsType.text;
    case 3:
      return ContentsType.sheet;
    case 4:
      return ContentsType.youtube;
    default:
      return ContentsType.free;
  }
}

enum PlayState {
  none,
  init,
  start,
  pause,
  end,
  disposed,
}
