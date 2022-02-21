import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/my_widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_client/my_widgets/dialogs.dart';


class LogInScreen extends StatefulWidget {
  const LogInScreen({Key key}) : super(key: key);

  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool noUserFoundForEmail = false;
  bool wrongPassword = false;
  bool skipToDashBoard = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController pwdController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;

  String modifiedUsername(String username) {
    String prevText = '1';
    String currentText = username.trim().toLowerCase().replaceAll(' ','|')+'|';

    while(prevText != currentText){
      prevText = currentText;
      currentText = currentText.replaceAll('||','|');
    }

    print('-----segmented text: $currentText-----');
    return currentText;
  }

  void startLoading() {
    setState(() {
      isLoading = true;
    });
  }

  void stopLoading() {
    setState(() {
      isLoading = false;
    });
  }

  ///validation callbacks
  String usernameValidation(var value) {
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).invalidName;
    }else if(wrongPassword) {
      return 'wrong name or password'; //todo: translate
    }else return null;
  }

  String pwdValidation(var value) {
    if(value == null || value.isEmpty) return AppLocalizations.of(context).invalidPwd;

    else if(wrongPassword) return 'wrong name or password';

    ///password cannot contain spaces
    else if (value.contains(' ')) return 'Password cannot contain empty spaces';

    else return null;
  }

  Future<void> login() async{
    ///if user is already signed in, sign out
    try {
      await auth.signOut();
      debugPrint('-------This user was already signed in-------');
      debugPrint('-------Signing this user out--------');
    }catch(e) {
      debugPrint('------This use is not yet signed in--------;');
    }

    ///check for internet connection
    if(!(await Dialogs(context:  context).checkConnectionDialog().timeout(Duration(seconds: 3),onTimeout: () => false))) return;

    ///reset all the flags
    noUserFoundForEmail = false;
    wrongPassword = false;

    if(formKey.currentState.validate()) {
      startLoading();
      debugPrint('--email: ${modifiedUsername(usernameController.text)}');
      debugPrint('password: ${pwdController.text}');
      try {
        UserCredential user = await auth.signInWithEmailAndPassword(
            email: modifiedUsername(usernameController.text) + pwdController.text+'@gmail.com',
            password: pwdController.text).timeout(Duration(seconds: 3),
            onTimeout: () async{
              try {
                await auth.signOut();
              }catch(e) {

              }
              return null;
        });

        if(user != null) {
          Navigator.pushNamed(context, '/SelectedQueuesScreen');
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          debugPrint('No user found for that email.');

          ///set flag for wrong email true;
          noUserFoundForEmail = true;
        } else if (e.code == 'wrong-password')
          debugPrint('Wrong password provided for that user.');
        ///set flag for wrong password true
        wrongPassword = true;
      }
      stopLoading();
      formKey.currentState.validate();
    }

  }


  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: ()async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ModalProgressHUD(
          inAsyncCall: isLoading,
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: ListView(
                  children: [
                    SizedBox(
                      height: 50,
                    ),
                    Center(child: Text( locale.login ,
                      style: TextStyle(
                        color: appColor,
                        fontSize: 30,
                      ),)),
                    MyTextField(controller: usernameController, labelText: locale.enterName, hintText: 'e.g Ngwa Mark', validator: usernameValidation ),
                    MyTextField(controller: pwdController, labelText: locale.enterPwd, hintText: locale.pwd, obscureText: true, validator: pwdValidation,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(locale.noAccount,
                                style: TextStyle(
                                  color: Colors.black,
                                )),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/SignUpScreen');
                              },
                              child: Text(locale.register,
                                  style: TextStyle(
                                    color: Colors.lightBlue,
                                  )),
                            )
                          ],
                        ),
                      ],
                    ),
                    FlatButton(
                        minWidth: 400,
                        color: appColor,
                        onPressed: () async{
                          startLoading();

                          if(!await Dialogs(context: context).appIsUpToDateDialog().timeout(Duration(seconds: 3), onTimeout: ()=> false)) {
                            ///exit if the app is not up to date
                            stopLoading();
                            return;
                          }
                          await login();
                          stopLoading();
                        },
                        child: Text(locale.login,
                            style: TextStyle(
                                color: Colors.white
                            )))
                  ]
              ),
            ),
          ),
        ),
      ),
    );
  }
}
