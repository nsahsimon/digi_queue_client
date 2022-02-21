//this widget displays some useful information about any selected queue in the 'search screen'
//its going to be be displayed as a bottom sheet widget
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';
import 'package:provider/provider.dart';
import 'package:no_queues_client/data/selected_queues.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:no_queues_client/transactions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_client/data/settings_data.dart';
import 'package:intl/intl.dart';
import 'package:no_queues_client/my_widgets/dialogs.dart';
import 'package:no_queues_client/onesignal.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:intl/date_symbol_data_local.dart';
//gives detailed information about the each queue

class QProfile extends StatefulWidget {
  final Queue queue;
  QProfile(this.queue);

  @override
  _QProfileState createState() => _QProfileState();
}

class _QProfileState extends State<QProfile> {
  bool joiningQueue = false;
  int clientCount = 0;
  int timePeriod = 5; //this is the average time per client in minutes
  int initialPosition = 0;
  bool open = true;
  String location = '';
  String name = '';
  String openingTime = '6:30';
  String closingTime = '16:45';
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  bool isLoading = false;
  bool hasPaid = false; // TODO: set this variable to false in the real app
  bool onTransactionScreen = false;
  TextEditingController numberController = TextEditingController();
  String amount = '2';
  String phoneNumber;
  String description = 'No Description';
  bool hasAdminAlreadyPaid = false;

  void startLoad() {
    setState(() {
      isLoading = true;
    });
  }

  void stopLoad() {
    setState((){
      isLoading = false;
    });
  }


  String openTime() {
    if('en' == Provider.of<SettingsData>(context, listen: false).getAppLang) return DateFormat('hh:mm a').format(DateFormat('h:m').parse(openingTime));
    return DateFormat('HH:mm').format(DateFormat('h:m').parse(openingTime));
  }

  String closeTime() { //'H' is used for the 24 hour clock while 'h' is used for the 12 hour clock
    if('en' == Provider.of<SettingsData>(context, listen: false).getAppLang) return DateFormat('hh:mm a').format(DateFormat('h:m').parse(closingTime));
    return DateFormat('HH:mm').format(DateFormat('h:m').parse(closingTime));
  }

  Future<bool> recordPayment() async{
    try {
      await db.collection('client_details').doc(auth.currentUser.uid).set({
        'paid_for' : FieldValue.arrayUnion([widget.queue.id])
      },
          SetOptions(merge: true));
      return true;
    }catch(e) {
      debugPrint(e);
      return false;
    }
  }

  ///records the reference for the ungoing payment transaction
  ///This functions stores the transaction reference in the firebase database
  Future<void> storeTransactionReference({String reference, String token}) async {
    try {
      await db.collection('client_details').doc(auth.currentUser.uid).set({
        'last_transaction_reference' : '$reference',
        'token' : '$token'
      },
      SetOptions(merge: true));
    }catch (e) {
      debugPrint('$e');
      debugPrint('----unable to store the transaction details in firebase-------');
      // TODO
    }
  }

  ///Check if the client has any pending payments
  Future<bool> hasPayed() async {
    String token;
    String reference;
    var status;
    ///This method checks the status of the transactin using the re
    Future<String> transactionStatus() async {
      debugPrint(token);
      var headers = {
        'Authorization': token,
        'Content-Type': 'application/json'
      };

      var request = http.Request('GET', Uri.parse('https://www.campay.net/api/transaction/$reference/'));
      request.headers.addAll(headers);

      try {
        http.StreamedResponse response = await request.send();
        var result = await response.stream.bytesToString();
        status = convert.json.decode(result)['status'];

        debugPrint('transactions status: $status');
        if (response.statusCode == 200) {
          debugPrint('successful retrieval of transaction status');
          debugPrint(result);
          if (status == 'SUCCESSFUL')
            return 'SUCCESSFUL';
          else if(status == 'FAILED')
            return 'FAILED';
          else if(status == 'PENDING')
            return 'PENDING';
        }
        else {
          debugPrint('${response.statusCode}');
          debugPrint(response.reasonPhrase);
          return 'ERROR1';
        }
      } catch (e) {
        debugPrint(e.message);
        return 'ERROR2';
      }
    }


    bool result = false;
    ///Beneath is the previous logic for the hasPayed method
    ///might need to uncomment these lines of code in case things go wrong!!
    // try {
    //     DocumentReference clientRef = db.collection('client_details').doc(auth.currentUser.uid);
    //     var clientDoc = await clientRef.get();
    //     if(clientDoc['paid_for'].contains(widget.queue.id) == true) {
    //       result = true;
    //     }else {
    //       result = false;
    //     }
    // }catch(e) {
    //   debugPrint(e);
    //   result = null;
    // }
    // return result;


    ///New logic for this method
    try {
      DocumentReference clientRef = db.collection('client_details').doc(auth.currentUser.uid);
      var clientDoc = await clientRef.get();
      token = clientDoc['token'];
      reference = clientDoc['last_transaction_reference'];

      if(reference == null || token == null || token == '' || reference == '') result = false;
      else {
        if(await transactionStatus() == 'SUCCESSFUL') return true;
        else return false;
      }
    }catch(e) {
      debugPrint('$e');
      result = null;
    }
    return result;
  }

  ///Checking if the service provider has paid for the service
  Future<bool> hasAdminPaid() async{

    DocumentReference managerRef = db.collection('manager_details').doc(widget.queue.id);
    int _accountBalance;
    int _costPerClient;

    try {
      _accountBalance = (await managerRef.get())['account_balance'];
      _costPerClient = (await managerRef.get())['cost_per_client'];
      debugPrint('Account balance: $_accountBalance');
      debugPrint('Cost per client: $_costPerClient');
    }catch(e) {
      debugPrint('$e');
      debugPrint('Unable to retrieve account balance details');
      return null;
    }

    if(_accountBalance == null || _costPerClient == null) return null;
    if(_accountBalance >= _costPerClient) {
      hasAdminAlreadyPaid = true;
      return true;
    }else if (_accountBalance < _costPerClient) {
      hasAdminAlreadyPaid = false;
      return false;
    }else {
      return null;
    }
  }

  Future<bool> alreadyJoinedThisQueue(BuildContext context) async{
    if (await Dialogs(context: context).checkConnectionDialog()) {
      print('----there is internet connection----');
      if(Provider.of<SelectedQueues>(context, listen: false).contains(widget.queue)) {
        print('-----you\'ve already joined this queue ---');
        return true;
      }
        QuerySnapshot  doc =  await db.collection('manager_details').doc(widget.queue.id).collection('subscribers').where('client_id', isEqualTo: auth.currentUser.uid).get();
        try {
          if(doc.docs.isNotEmpty) {
            print('-----you\'ve already joined this queue ---');
          }
          return doc.docs.isNotEmpty;
        } catch(e) {
          return false;
        }
    }else {
      print('-----there is no internet connection------');
      return true;
    }
    }

  int secondNotificationIndex(int firstClientIndex, int clientCount,){
    double percent = 0.8; // percentage coverage for first notification
    int initialPosition = clientCount;
    int notificationPosition;
    notificationPosition = (initialPosition - percent * (initialPosition - 1)).floor();
    int indexDistance = initialPosition - notificationPosition;
    return indexDistance + firstClientIndex - 1;
  }

  int firstNotificationIndex(int firstClientIndex, int clientCount,){
    int _secondNotificationIndex(int firstClientIndex, int clientCount,){
      double percent = 0.8; // percentage coverage for first notification
      int initialPosition = clientCount;
      int notificationPosition;
      notificationPosition = (initialPosition - percent * (initialPosition - 1)).floor();
      int indexDistance = initialPosition - notificationPosition;
      return indexDistance + firstClientIndex - 1;
    }

    double percent = 0.6; // percentage coverage for first notification
    int initialPosition = clientCount;
    int notificationPosition;
    notificationPosition = (initialPosition - percent * (initialPosition - 1)).floor();
    int indexDistance = initialPosition - notificationPosition;
    int firstNotificationIndex = indexDistance + firstClientIndex - 1;
    int secondNotificationIndex = _secondNotificationIndex(firstClientIndex, clientCount);

    ///if the first notification index is greater than or equal to the second notification index , then only notify the user once
    return (firstNotificationIndex >= secondNotificationIndex) ? -1 : firstNotificationIndex;
  }

  String formattedDuration(int timeInSecs) {
    int hour = (timeInSecs/3600).floor();
    int min = ((timeInSecs%3600)/60).floor();
    if(min == 0) {
      return (hour == 0)? "$timeInSecs seconds" : ((hour == 1) ? "$hour Hr" : "$hour Hrs");
    }else {
      if(hour == 0) {
        return (min == 1)? "$min min" : "$min mins";
      }
      else if(hour == 1) {
        return (min == 1)? "$hour Hr $min min" : "$hour Hr $min mins";
      }
      else {
        return (min == 1)? "$hour Hrs $min min" : "$hour Hrs $min mins";
      }
    }
  }

  Future<void> joinQueue() async{
  debugPrint('-----my id ${auth.currentUser.uid}-----');
        int clientIndex;

        ///get the onesignal token Id
        String _oneSignalTokenId = await PushNotificationService().getTokenId();

        ///add this client to the list of clients subscribed to this queue;
        try {
          await db.runTransaction((transaction) async{

            DocumentReference clientReference = FirebaseFirestore.instance.collection('client_details').doc('${auth.currentUser.uid}');
            DocumentSnapshot clientDetails = await transaction.get(clientReference);
            String firebaseNotificationToken = '${await FirebaseMessaging.instance.getToken()}';
            String clientName = clientDetails['name'];

            DocumentReference managerReference = db.collection('manager_details').doc(widget.queue.id);
            DocumentSnapshot managerDetails = await transaction.get(managerReference);

            int firstClientIndex = managerDetails['first_client_index'];
            int clientCount = managerDetails['client_count'];
            int _costPerClient = managerDetails['cost_per_client'];
            debugPrint('cost per client: $_costPerClient');

            /// if this client is the first subscriber of this service,
            clientIndex = firstClientIndex + clientCount;
            initialPosition = clientCount + 1;

            DocumentReference subsSummaryDoc = db.collection('manager_details').doc(widget.queue.id).collection('subscribers').doc('summary');
            transaction.set(subsSummaryDoc, {
              'subscribers' : FieldValue.arrayUnion(
                [
                  { 'id': auth.currentUser.uid,
                    'name': clientName,
                  }
                ]
              )
            },
            SetOptions(merge: true));

            DocumentReference subscriberReference = db.collection('manager_details').doc(widget.queue.id).collection('subscribers').doc(auth.currentUser.uid);
            transaction.set(subscriberReference, {
              'skip_count' : 0,
              'client_id' : auth.currentUser.uid,
              'lang' : Provider.of<SettingsData>(context, listen: false).getAppLang,
              'timestamp' : FieldValue.serverTimestamp(),
              'initial_position' : initialPosition,
              'client_index' : clientIndex,
              'registered' : true,
              'name': clientName,
              'phone': phoneNumber,
              'one_signal_token_id': _oneSignalTokenId,
              'firebaseDeviceToken' : firebaseNotificationToken,
              'first_notification_index' : firstNotificationIndex(firstClientIndex, clientCount), //the first client index at which the current client is to be firstly notified
              'second_notification_index' : secondNotificationIndex(firstClientIndex, clientCount) //the first client index at which the current client is to be secondly notified.
            },);
            transaction.set(clientReference, {
              'paid_for' : [], ///once a client joins a queue, his payment details are reset
              'last_transaction_reference' : '', ///once a client joins a queue, his payment details are reset
              'token' : '', ///once a client joins a queue, his previous payment details are reset
              'my_queues' : FieldValue.arrayUnion([{
                'id' : widget.queue.id,
                'name' : widget.queue.name
              }]) },
              SetOptions(merge: true),);


            managerReference = db.collection('manager_details').doc(widget.queue.id);

            ///check if this client is covered by the administrator
            if(hasAdminAlreadyPaid == true) {

              ///If this client is covered by the administrator, deduct unit cost from the account balance
              transaction.update(managerReference, {
                'client_count': FieldValue.increment(1),
                'account_balance': FieldValue.increment(-_costPerClient) //deduct a unit cost from the current client Id
              });
              hasAdminAlreadyPaid = false;
            }else {
              ///Once the client joins a queue, set the payment status to false

              transaction.update(managerReference, {
                'client_count': FieldValue.increment(1),
              });
            }

          },
            timeout: Duration(seconds: 10),
          );
          //TODO: Display a dialog box when client successfully joins the queue.
        } catch(e) {
          debugPrint('--------Failed to join queue---------');
          debugPrint('$e');
          await Dialogs(context: context).failureDialog();
          Navigator.pop(context);
          return;
        }
        debugPrint('-------successfully joined Queue--------');
        await Dialogs(context: context).successDialog();
        Provider.of<SelectedQueues>(context, listen: false).add(widget.queue);
        Navigator.popAndPushNamed(context, '/SelectedQueuesScreen');
    }

  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async {
        return !isLoading;
      },
      child: ModalProgressHUD(
        inAsyncCall: isLoading,
        child:  StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('manager_details').doc(widget.queue.id).snapshots(),
          builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    color: Colors.black.withOpacity(0.55),
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                            color: appColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            )
                        ),
                        child: Center(
                          child: Text('${AppLocalizations.of(context).pleaseWait}....',
                              style: TextStyle(
                                color: Colors.white,
                              ),)
                        )),
                  );
                } else {
                  DocumentSnapshot queueDetails = snapshot.data;
                  if(queueDetails.exists) {
                    clientCount = queueDetails['client_count'];
                    name = queueDetails['name'];
                    open = queueDetails['open'];
                    openingTime = queueDetails['opening_time'];
                    closingTime = queueDetails['closing_time'];
                    location = queueDetails['location'];
                    try{
                      description = queueDetails['description'];
                    }catch(e) {
                      print(e);
                    }
                    try{
                      timePeriod = queueDetails['time_period'];   //timePeriod is average time for one client to receive a service,
                    }catch(e){
                      print(e);
                    }
                    print('-----clientCount: $clientCount------');
                  }
                  return WillPopScope(
                    onWillPop: () async => (!joiningQueue),
                    child: Container(
                      color: Colors.black.withOpacity(0.55),
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              )
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                      children: [
                                        Center(
                                          child: Text(
                                            locale.details,
                                            style: TextStyle(
                                              color: appColor,
                                              fontSize: 25,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 70.0),
                                          child: Divider(
                                            thickness: 3,
                                            color: appColor,
                                          ),
                                        ),
                                      ]
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    child: Container(
                                        color: appColor,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SingleChildScrollView(
                                            child: Column(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .spaceEvenly,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text('${locale.name}: ',
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                      )),
                                                  Text(
                                                      name,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      )
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text('${locale.location}: ',
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                      )
                                                  ),
                                                  Text(
                                                      location,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      )
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .center,
                                                    children: [
                                                      Text('${locale.startsAt}: ',
                                                          style: TextStyle(
                                                            color: Colors.black54,
                                                          )),
                                                      Text(
                                                          openTime(),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          )
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .center,
                                                    children: [
                                                      Text('${locale.state}: ',
                                                          style: TextStyle(
                                                            color: Colors.black54,
                                                          )),
                                                      Text(
                                                          open ? AppLocalizations.of(context).open : AppLocalizations.of(context).closed,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          )
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .center,
                                                    children: [
                                                      Text('${locale.endsAt}: ',
                                                          style: TextStyle(
                                                            color: Colors.black54,
                                                          )),
                                                      Text(
                                                          closeTime(),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          )
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .center,
                                                    children: [
                                                      Text('${locale.currentLength}: ',
                                                        style: TextStyle(
                                                          color: Colors.black54,
                                                        ),),
                                                      Text(
                                                          (clientCount == 1) ? '1 ${AppLocalizations.of(context).person}' : '$clientCount ${AppLocalizations.of(context).people}',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          )
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .center,
                                                    children: [
                                                      Text('${AppLocalizations.of(context).estimatedWaitingTime}: ',
                                                        style: TextStyle(
                                                          color: Colors.black54,
                                                        ),),
                                                      Text(
                                                          '${formattedDuration(clientCount * timePeriod)}',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          )
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .center,
                                                    children: [
                                                      Text('${AppLocalizations.of(context).description}',
                                                        style: TextStyle(
                                                          color: Colors.black54,
                                                        ),),
                                                      Text(
                                                          '$description',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          )
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                ]
                                            ),
                                          ),
                                        )
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        elevation: MaterialStateProperty.all(10),
                                        backgroundColor: MaterialStateProperty.all(
                                            appColor),
                                      ),
                                      child: Text(
                                        locale.joinQueue,
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () async {
                                        startLoad();
                                        ///make sure that the app is up to date before joining the queue
                                        if(await Dialogs(context: context).appIsUpToDateDialog() == false) {
                                          stopLoad();
                                          return;
                                        }

                                        if (!await alreadyJoinedThisQueue(context)) {
                                          //TODO: uncomment this line of code and remove the line after to reintegrate online payment
                                          bool paymentStatus = await hasPayed() || await hasAdminPaid();
                                          bool result = (paymentStatus == true) ? true :( (paymentStatus == false) ? await Transactions(context: context, recordPaymentCallback: recordPayment, storeTransactionReference: storeTransactionReference ).mobileMoneyPayment() : null );
                                          print('----result in queue profile: $result-------');
                                          if (result != null && result) {
                                            phoneNumber = await Navigator.push(context, MaterialPageRoute(builder: (context) => GetSmsNum()));
                                            if(phoneNumber != null){
                                              joiningQueue = true;
                                               await joinQueue();
                                               joiningQueue = false;
                                               stopLoad();
                                              return;
                                            }
                                          }
                                          await Dialogs(context: context).failureDialog();
                                        }
                                        stopLoad();
                                        //TODO: Do Something
                                      },
                                    ),
                                  ),
                                ),
                              ]
                          )
                      ),
                    ),
                  );
          }
          }
        ),
      ),
    );
  }
}

class GetSmsNum extends StatefulWidget {
  @override
  _GetSmsNumState createState() => _GetSmsNumState();
}

class _GetSmsNumState extends State<GetSmsNum> {
  final formKeySMSNum = GlobalKey<FormState>();
  TextEditingController numberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        ///exit this screen only if the user approves
        return await Dialogs(context: context).confirmationDialog(text: 'Are you sure you want to quit?'); //todo: translate
      },
      child: Scaffold(
        backgroundColor: appColor,
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              height: 270,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                      Radius.circular(20)
                  )
              ),
              child: Form(
                key: formKeySMSNum,
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context).requestPhone,
                        textAlign: TextAlign.center),
                    Text(AppLocalizations.of(context).phoneRequestWarning,
                        style: TextStyle(
                          color: Colors.red,),
                        textAlign: TextAlign.center
                    ),

                    SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                        keyboardType: TextInputType.number,
                        controller: numberController,
                        validator: (newNumber) {
                          String newNum = newNumber.trim().replaceAll(' ','');
                          if(newNum.length != 9) {
                            return AppLocalizations.of(context).invalidNum;
                          }
                          else if (newNum.substring(0,1) != '6') {
                            return AppLocalizations.of(context).numMustBeginWith6;
                          }
                          else return null;
                        }
                    ),
                    FlatButton(
                        color: appColor,
                        onPressed: () {
                          if (formKeySMSNum.currentState.validate()) {
                              Navigator.pop(context,numberController.text.replaceAll(' ',''));
                          }
                        },
                        child: Text('ok'))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

