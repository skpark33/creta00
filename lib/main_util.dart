import 'package:creta00/studio/studio_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:creta00/common/util/logger.dart';
import 'common/util/my_utils.dart';
import 'model/book.dart';
import 'model/model_enums.dart';
import 'model/users.dart';
import 'player/video/simple_video_player.dart';

class MainUtil {
  static Widget drawBackground(double width, double height, BookModel book) {
    logHolder.log("drawBackground $width, $height", level: 5);

    if (book.thumbnailUrl.value.isEmpty || book.thumbnailType.value == ContentsType.image) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(0),
          bottomLeft: Radius.circular(0),
        ),
        child: SizedBox.expand(
          child: FittedBox(
            alignment: Alignment.center,
            fit: BoxFit.cover,
            child: SizedBox(
              width: width,
              height: height,
              child: book.thumbnailUrl.value.isEmpty
                  ? defaultBGImage()
                  : Image.network(book.thumbnailUrl.value, fit: BoxFit.cover),
            ),
          ),
        ),
      );
    }
    if (book.thumbnailType.value == ContentsType.video) {
      return SimpleVideoPlayer(
        globalKey: GlobalKey<SimpleVideoPlayerState>(),
        url: book.thumbnailUrl.value,
        realSize: Size(width, height),
        aspectRatio: book.thumbnailAspectRatio.value,
        onAfterEvent: () {},
      )..init();
    }
    return defaultBGImage();
  }

  static void goToStudio(BuildContext context, UserModel user) {
    studioMainHolder = StudioMainScreen(mainScreenKey: GlobalKey<MainScreenState>(), user: user);
    naviPush(context, studioMainHolder!);
  }

  static BookModel createDefaultBook({String userId = 'b49@sqisoft.com'}) {
    return BookModel('나의 첫 콘텐츠북', userId,
        "'You could do it simple and plain'\nfrom [Sure thing] of Miguel.", "");
  }
}
