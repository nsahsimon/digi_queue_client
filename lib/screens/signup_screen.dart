import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/my_widgets/custom_text_field.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_client/my_widgets/dialogs.dart';


class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  final formKey = GlobalKey<FormState>();
  String serviceCode;
  bool _isPhoneNumberWorking = false;
  bool userExists = false;
  bool accountAlreadyExists = false;
  bool weakPassword = false;

  bool isLoading = false;
  bool obscureText = true;

  void startLoading() {
    if(mounted) setState(() { isLoading = true;});
  }

  void stopLoading() {
    if(mounted) setState(() { isLoading = false;});
  }


  String pwdValidation(var value) {

    ///password cannot be empty
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).invalidPwd;
    }
    ///password cannot contain @
    else if (value.contains('@')) {
      return AppLocalizations.of(context).pwdResCharWarning1;
    }
    ///password cannot contain |
    else if (value.contains('|')) return AppLocalizations.of(context).pwdResCharWarning2;

    ///password cannot contain spaces
    else if (value.contains(' ')) return 'Password cannot contain empty spaces';

    else if (value != confirmPasswordController.text) {
      return AppLocalizations.of(context).pwdDonotMatch;
    }

    else return null;
  }


  ///segments text into its various components(words) using '|'
  String modifiedUsername(String username) {
   String prevText = '1';
    String currentText = username.trim().toLowerCase().replaceAll(' ','|') + '|';

    while(prevText != currentText){
      prevText = currentText;
      currentText = currentText.replaceAll('||','|');
    }

    print('-----segmented text: $currentText-----');
    return currentText;
  }


  ///this function takes in '|'(stroke) segmented text as input then outputs ' ' (single space) segmented text
  String realUsername(String newUsername) {
    String username = modifiedUsername(newUsername);
    List<String> _usernameList = username.split('|');
    String _username = '';
    for(var name in _usernameList) {
      print('----name = ${name}----');

      ///ensure that name does not contain '@'
      if(!name.contains('@')){
        _username = _username + ' ' + name.toUpperCase();
      } //TODO:  '@' as a reserved character.
    }
    return _username.trim();
  }

  String confirmPwdValidation(var value) {

    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).invalidPwd;
    }
    else if (value != pwdController.text) {
      return AppLocalizations.of(context).pwdDonotMatch;
    }
    else if (value.contains('@')) {
      return AppLocalizations.of(context).pwdResCharWarning1;
    }
    else if (value.contains('|')) return AppLocalizations.of(context).pwdResCharWarning2;
    else return null;
  }

  String usernameValidation(String value) {
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).invalidName;
    }else if (value.length > 20) {
      return AppLocalizations.of(context).longName;
    } else if (value.contains('@')) {
      return AppLocalizations.of(context).pwdResCharWarning1;
    }else if(userExists) {
      userExists = false;
      return AppLocalizations.of(context).userExists;
    }else if(accountAlreadyExists) {
      return 'account already exists';
    }
    else if (value.contains('|')) return AppLocalizations.of(context).pwdResCharWarning2;
    else return null;
  }


  TextEditingController pwdController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> checkUserExistence (){}

  Future<bool> addClientDetails() async{
    String token = await FirebaseMessaging.instance.getToken();
    bool success = false;
    DocumentReference clientRef = db.collection('client_details').doc('${auth.currentUser.uid}');

    try {
      await clientRef.set({
        'name' : realUsername(usernameController.text),
        'password': pwdController.text,
        'paid_for' : [],
        'id' : auth.currentUser.uid,
        'firebaseDeviceToken' : '$token'
      });
      success = true;
    }catch (e) {
      print(e);
      success = false;
      // TODO
    }

    return success;
  }

  Future<void> createAccount() async{

    ///check the internet connection
    if(!(await Dialogs(context:  context).checkConnectionDialog().timeout(Duration(seconds: 3),onTimeout: () => false))) return;

    ///check for any available updates
    if((await Dialogs(context: context).appIsUpToDateDialog().timeout(Duration(seconds: 3),onTimeout: () => false)) == false) return;

    ///reset flags
    accountAlreadyExists = false;
    weakPassword = false;

    Future<bool> userAlreadyExists(String username ,String password) async{
      await FirebaseAuth.instance.signInAnonymously();
      try{
        QuerySnapshot doc = await db.collection('client_details').where('name', isEqualTo: username).where('password', isEqualTo: password).limit(1).get();
        if(doc.docs.isNotEmpty) {
          print('----recieved non empty documents----');
          FirebaseAuth.instance.signOut();
          return true;
          } //user doesn't yet exist
        print("----received empty document------");
          FirebaseAuth.instance.signOut();
          return false;
          //user already exists
      } catch(e) {
        print('------something went wrong-------');
        FirebaseAuth.instance.signOut();
        return false;
      }
    }

    if(await userAlreadyExists(modifiedUsername(usernameController.text), pwdController.text)) {
      debugPrint('------username already Exists------');
     setState((){
       userExists = true;
     });
    }

    ///Stop loading because we need to call the formKey.currentState.validate() function
    stopLoading();
    if(formKey.currentState.validate()) {
      ///resume the loading process since we are done with the formkey.currentState.validate()
      startLoading();

      if(true) {
        try {
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
              email: modifiedUsername(usernameController.text) + pwdController.text+'@gmail.com',
              password: pwdController.text
          ).timeout(Duration(seconds: 3));


          ///add the client details
          if (await addClientDetails().timeout(Duration(seconds: 3),onTimeout: () => false)) {
            final SnackBar msg = SnackBar(content: Text('Success'), duration: Duration(seconds: 1)); //todo: translate
            ScaffoldMessenger.of(context).showSnackBar(msg);
            await Dialogs(context: context).successDialog();

            /// this prevents the user from automatically logging in after signing up
            try {
              await auth.signOut();
            } catch (e) {
              debugPrint('----failed to sign out------');
            }

            Navigator.pop(context);
          }
          ///if addition of client details fails, do this
          else {
            final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).failed), duration: Duration(seconds: 1));
            ScaffoldMessenger.of(context).showSnackBar(msg);
          }

        } on FirebaseAuthException catch (e) {
          ///inspecting the various firebase exceptions gotten
          if (e.code == 'weak-password'){
            debugPrint('the password provided is too weak.');

            ///set weak password flag true
          weakPassword = true;}
          else if (e.code == 'email-already-in-use'){
            debugPrint('An account already exists for that email.');

            ///set account already exists flag to true
          accountAlreadyExists = true;
          }

          ///revalidate the form
          formKey.currentState.validate();
        } catch (e) {
          debugPrint(e);
          final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).failed), duration: Duration(seconds: 1));
          ScaffoldMessenger.of(context).showSnackBar(msg);
        }

        var user = auth.currentUser;
        debugPrint('the user is: $user ');
        if(user != null) print(user.email);
        if ( auth.currentUser != null) {
        }
      } else print('Passwords don\'t match');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: appColor,
          title: Text(AppLocalizations.of(context).createAccount,
              style: TextStyle (
                color: Colors.white,
              )
          )
      ),
      body: WillPopScope(
        onWillPop: () async {
          return !isLoading;
        },
        child: ModalProgressHUD(
          inAsyncCall: isLoading,
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ListView(
                  children: [
                    MyTextField(controller: usernameController, labelText: AppLocalizations.of(context).enterName, hintText: 'e.g Ngwa Peter', validator: usernameValidation,),
                    MyTextField(controller: pwdController, labelText: AppLocalizations.of(context).enterPwd, hintText: AppLocalizations.of(context).enterPwd, obscureText: obscureText, validator: pwdValidation),
                    MyTextField(controller: confirmPasswordController, labelText: AppLocalizations.of(context).kfirmPwd, hintText: AppLocalizations.of(context).enterPwd, obscureText: obscureText, validator: confirmPwdValidation),
                    FlatButton(
                        minWidth: MediaQuery.of(context).size.width,
                        color: appColor,
                        onPressed: () async{
                          //TODO: Add some authentication logic
                          startLoading();
                          await createAccount();
                          stopLoading();
                        },
                        child: Text(
                            AppLocalizations.of(context).register,
                            style: TextStyle(
                              color: Colors.white,
                            )
                        )),
                    SizedBox(
                      height: 20,
                    )
                  ]
              ),
            ),
          ),
        ),
      ),
    );
  }
}
