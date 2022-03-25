import 'package:creta00/studio/save_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'studio/studio_main_screen.dart';
import 'model/users.dart';
import 'model/book.dart';
import 'constants/styles.dart';
import 'db/creta_db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //for firebase
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          appId: FirebaseConfig.appId,
          storageBucket: FirebaseConfig.storageBucket,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          projectId: FirebaseConfig.projectId)); // for firebase
  runApp(const MyApp());
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    saveManagerHolder = SaveManager();
    studioMainHolder = StudioMainScreen(
        book: BookModel('나의 첫 콘텐츠북', 'skpark@sqisoft.com'),
        user: UserModel(id: 'skpark@sqisoft.com'));
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light().copyWith(
          appBarTheme: AppBarTheme(
            color: MyColors.primaryColor,
            centerTitle: true,
            titleTextStyle: MyTextStyles.subtitle1,
            actionsIconTheme: const IconThemeData(color: MyColors.primaryColor),
          ),
          primaryColor: MyColors.primaryColor,
          scaffoldBackgroundColor: MyColors.bgColor,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
              .apply(bodyColor: MyColors.primaryText),
          canvasColor: MyColors.secondaryColor,
          inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(color: MyColors.mainColor),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: MyButtonStyle.b1,
          ),
          tabBarTheme: TabBarTheme(
            labelStyle: MyTextStyles.body2, // color for text
          ),
          hoverColor: Colors.red.shade100,
          colorScheme: ThemeData()
              .colorScheme
              .copyWith(primary: MyColors.primaryColor)
              .copyWith(secondary: MyColors.secondaryColor),
        ),
        home: studioMainHolder!);
  }
}
