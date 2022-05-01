import '../constants/strings.dart';

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
  none,
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
    case BookType.none:
      return 99;
  }
}

String bookTypeToString(BookType value) {
  switch (value) {
    case BookType.signage:
      return MyStrings.signage;
    case BookType.electricBoard:
      return MyStrings.electricBoard;
    case BookType.presentaion:
      return MyStrings.presentation;
    case BookType.nft:
      return MyStrings.nft;
    case BookType.none:
      return MyStrings.none;
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
      return BookType.none;
  }
}

enum ContentsType {
  video,
  image,
  text,
  sheet,
  youtube,
  instagram,
  web,
  pdf,
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
    case ContentsType.instagram:
      return 5;
    case ContentsType.web:
      return 6;
    case ContentsType.pdf:
      return 7;
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
    case 5:
      return ContentsType.instagram;
    case 6:
      return ContentsType.web;
    case 7:
      return ContentsType.pdf;
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
  manualPlay,
}

enum AnimeType {
  none,
  carousel,
  flip,
  scale,
  enlarge,
}

int animeTypeToInt(AnimeType value) {
  switch (value) {
    case AnimeType.none:
      return 0;
    case AnimeType.carousel:
      return 1;
    case AnimeType.flip:
      return 2;
    case AnimeType.scale:
      return 3;
    case AnimeType.enlarge:
      return 4;
  }
}

AnimeType intToAnimeType(int t) {
  switch (t) {
    case 0:
      return AnimeType.none;
    case 1:
      return AnimeType.carousel;
    case 2:
      return AnimeType.flip;
    case 3:
      return AnimeType.scale;
    case 4:
      return AnimeType.enlarge;
    default:
      return AnimeType.none;
  }
}

enum BoxType {
  rect,
  rountRect,
  circle,
  beveled,
  stadium,
}

int boxTypeToInt(BoxType value) {
  switch (value) {
    case BoxType.rect:
      return 0;
    case BoxType.rountRect:
      return 1;
    case BoxType.circle:
      return 2;
    case BoxType.beveled:
      return 3;
    case BoxType.stadium:
      return 4;
  }
}

BoxType intToBoxType(int t) {
  switch (t) {
    case 0:
      return BoxType.rect;
    case 1:
      return BoxType.rountRect;
    case 2:
      return BoxType.circle;
    case 3:
      return BoxType.beveled;
    case 4:
      return BoxType.stadium;
    default:
      return BoxType.rect;
  }
}

enum InProgressType {
  done,
  saving,
  contentsUploading, /*thumbnailUploading*/
}

String inProgressTypeToMsg(InProgressType type) {
  switch (type) {
    case InProgressType.done:
      return MyStrings.doneMsg;
    case InProgressType.saving:
      return MyStrings.saving;
    case InProgressType.contentsUploading:
      return MyStrings.contentsUploading;
    // case InProgressType.thumbnailUploading:
    //   return MyStrings.thumbnailUploading;
  }
}

enum PropertyType {
  book,
  page,
  acc,
  contents,
  settings,
}

int propertyTypeToInt(PropertyType value) {
  switch (value) {
    case PropertyType.book:
      return 0;
    case PropertyType.page:
      return 1;
    case PropertyType.acc:
      return 2;
    case PropertyType.contents:
      return 3;
    case PropertyType.settings:
      return 4;
  }
}

enum ACCType {
  normal,
  youtube,
}

int accTypeToInt(ACCType value) {
  switch (value) {
    case ACCType.normal:
      return 0;
    case ACCType.youtube:
      return 1;
  }
}

ACCType intToAccType(int t) {
  switch (t) {
    case 0:
      return ACCType.normal;
    case 1:
      return ACCType.youtube;
  }
  return ACCType.normal;
}
