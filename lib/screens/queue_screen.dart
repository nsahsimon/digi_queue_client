import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:no_queues_client/data/selected_queues.dart';
import 'package:provider/provider.dart';
import 'package:no_queues_client/screens/qr_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_client/data/bigData.dart';
import 'dart:io';
import 'package:no_queues_client/my_widgets/dialogs.dart';
import 'package:no_queues_client/my_widgets/connection_failure_alert.dart';
import 'package:provider/provider.dart';

class QueueScreen extends StatefulWidget {
  final Queue queue;
  QueueScreen(this.queue);

  @override
  _QueueScreenState createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  bool isLoading = false;
  int currentPosition = 0;
  int timePeriod = 5; //this is the average time per client in minutes
  int clientCount = 0;
  int initialPosition = 0;
  int firstClientIndex = 0;
  double percentage = 0;
  bool thereIsConnection = false;
  bool refreshButtonPressed = false;
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore  db = FirebaseFirestore.instance;
  int clientIndex = 1;
  Timestamp mostRecentTransitionTime = Timestamp.fromDate(DateTime.now());
  bool isOpen = true; //Holds information about the current state of the queue i.e. if the queue is open or closed
  Timestamp pauseTime = Timestamp.now(); // Time at which the queue was paused.
  int pauseDuration = 300; //duration of the pause period in  seconds. Defaults to 300 seconds


  void startLoad() {
    setState(() {
    isLoading = true;
        }); }

  void stopLoad() {
    setState(() {
      isLoading = false;
    });
  }


  Future<void> deleteQueue () async{
    try {
      startLoad();
      DocumentReference clientReference = db.collection('client_details').doc(auth.currentUser.uid);
      await clientReference.set({
        'my_queues' : FieldValue.arrayRemove([{
          'id' : widget.queue.id,
          'name' : widget.queue.name,
        }])
      },
          SetOptions(merge: true),);
      stopLoad();
      Navigator.pop(context);
    }catch (e) {
      debugPrint(e.toString());
    }
    //TODO: Display a dialog box when client successfully joins the queue.
  }

  Future<void> getUpdatedClientInfo() async{
    startLoad();
    var provider = Provider.of<BigData>(context, listen: false);
    MyData prevData = provider.getData(widget.queue);
    debugPrint('----here is what i got from device-----');
    debugPrint('----first client index: ${prevData.prevFirstClientIndex}');
    debugPrint ('----client index: ${prevData.prevClientIndex}');
    debugPrint ('----initial client index : ${prevData.prevInitialClientPosition}');
    try{
      debugPrint('------updating client info-----');
      QuerySnapshot subscriberDocs ;
      if (thereIsConnection) {
        try {
          subscriberDocs = await db.collection('manager_details').doc(widget.queue.id).collection('subscribers')
              .where('client_id',isEqualTo: auth.currentUser.uid)
              .where('client_index', isNotEqualTo: prevData.prevClientIndex)
              .get();
        } catch (e) {
          debugPrint(e.toString());
          await Dialogs(context: context).poorInternetConnectionDialog();
        }
      }

          if (thereIsConnection && subscriberDocs.docs.isEmpty != true) {
            debugPrint('-----length of subscriber docs is: ${subscriberDocs.docs.length}');
            var subscriberDetails = subscriberDocs.docs.first;
            if (subscriberDetails.exists) {
                initialPosition = subscriberDetails['initial_position'];
                debugPrint('-------(from firestore) initial Position: $initialPosition-------');
                clientIndex = subscriberDetails['client_index'];
                debugPrint('--------(from firestore) client index: $clientIndex------');
                MyData newData = prevData;
                newData.setClientIndex(clientIndex);
                newData.setInitialPosition(initialPosition);
                provider.addData(widget.queue, newData);
            }
          }else {
            provider = Provider.of<BigData>(context, listen: false);
            MyData prevData = provider.getData(widget.queue);
            initialPosition = prevData.prevInitialClientPosition;
            debugPrint('-------(from device) initial Position: $initialPosition-------');
            clientIndex = prevData.prevClientIndex;
            debugPrint('--------(from device) client index: $clientIndex------');
          }
    }catch(e){
      debugPrint('$e');
      debugPrint('-----unable to update client info-------');
      //TODO: display an alert dialog asking user to check his internet connection.
    }
    stopLoad();
  }

  Future<bool> isThereConnection() async {
    try {
      final result = await InternetAddress.lookup('www.google.com');
      if(result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('------connected to the internet----');
        return true;
      }
      final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).noInternet), duration: Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(msg);
      return false;
    }on SocketException catch (e) {
      debugPrint('----you are not connected to the internet-----');
      final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).noInternet), duration: Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(msg);
      return false;
    }
  }

  Future<void> getUpdatedQueueInfo() async{
    startLoad();
    var provider = Provider.of<BigData>(context, listen: false);
    MyData prevData = provider.getData(widget.queue);
    try{
        debugPrint('-----updating queue info-----');
        QuerySnapshot queueDoc1, queueDoc2;
        if (thereIsConnection) {
        try {
          ///get the manager info only if the first client index has changed
          ///queueDoc1 is gotten when the first client changes
          queueDoc1 = await db.collection('manager_details')
                .where('id',isEqualTo: widget.queue.id)
                .where('first_client_index', isNotEqualTo: prevData.prevFirstClientIndex)
                .get();

          ///queueDoc2 is gotten when the queue is paused
          queueDoc2 = await db.collection('manager_details')
              .where('id',isEqualTo: widget.queue.id)
              .where('open', isNotEqualTo: prevData.prevIsOpen)
              .get();
        } catch (e) {
          debugPrint(e.toString());
          await Dialogs(context: context).poorInternetConnectionDialog();
        }

      }

        ///getting data from the queue1Doc
        if (thereIsConnection && (queueDoc1.docs.isEmpty != true || queueDoc2.docs.isEmpty != true)) {

          ///queueDetails is derived from either queueDoc1 or queueDoc2 depending on which is not empty
          var queueDetails;
          if(queueDoc1.docs.isEmpty != true) {
            queueDetails = queueDoc1.docs.first;
          } else {
            queueDetails = queueDoc2.docs.first;
          }
          if(queueDetails.exists) {
            firstClientIndex = queueDetails['first_client_index'];

            try {
              timePeriod = queueDetails['time_period'];
            }catch(e) {
              debugPrint('$e');
            }

            try {
                mostRecentTransitionTime = queueDetails['prev_transition_time'];
            }catch(e) {
              mostRecentTransitionTime = Timestamp.fromDate(DateTime.now());
              debugPrint('$e');
            }

            try {
              setState((){
                isOpen = queueDetails['open'] ?? true;
              });
            }catch(e) {
              debugPrint('$e');
            }

            try {
              setState((){
                pauseTime = queueDetails['pause_time'];
                pauseDuration = queueDetails['pause_duration'];
              });
            }catch(e) {
              debugPrint('$e');
            }

            debugPrint('------(from firestore) first client Index: $firstClientIndex-------');
            MyData newData = prevData;
            newData.setFirstClientIndex(firstClientIndex);
            newData.setTimePeriod(timePeriod);
            newData.setPrevTransitionTime(mostRecentTransitionTime);
            newData.setIsOpen(isOpen);
            newData.setPauseTime(pauseTime);
            newData.setPauseDuration(pauseDuration);
            provider.addData(widget.queue, newData);
            }
        }else {
          provider = Provider.of<BigData>(context, listen: false);
          MyData prevData = provider.getData(widget.queue);
          firstClientIndex = prevData.prevFirstClientIndex;
          timePeriod = prevData.prevTimePeriod;
          setState((){
            mostRecentTransitionTime = prevData.prevTransitionTime;
          });
          isOpen = prevData.prevIsOpen;
          pauseTime = prevData.prevPauseTime;
          pauseDuration = prevData.prevPauseDuration;

          debugPrint('------(from device) first client Index: $firstClientIndex-------');
          debugPrint('-------(from device) timePeriod: $timePeriod------');
          debugPrint('-------(from device) previousTransitionTime: $mostRecentTransitionTime------');
        }

    }catch(e){
      debugPrint(e.toString());
      //await Dialogs(context: context).poorInternetConnectionDialog();
      debugPrint('----was unable to get the queue info-------');
    }
    stopLoad();
  }

  void calculations(bool shouldSetState) {
    if(firstClientIndex == -1 || clientIndex == -1 || timePeriod == -1 || initialPosition == -1) {
      final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).connectionFailed));
      ScaffoldMessenger.of(context).showSnackBar(msg);
      Dialogs(context: context).poorInternetConnectionDialog();
      return;
    }
    if(clientIndex < firstClientIndex) {
      deleteQueue();
      return;
    }

    if (shouldSetState){
      setState((){
        currentPosition = clientIndex - firstClientIndex + 1;
      });
      debugPrint('-----currentPosition: $currentPosition ------------');
      debugPrint('----------initialPosition: $initialPosition -----------');

      if (initialPosition == 1)
        setState((){
          percentage = 1;
        });
      else {
        double result =
            (initialPosition - currentPosition) / (initialPosition - 1);
        setState((){
          if(result > 1 || result < 0) percentage = 0;
          else percentage = result;
        });
        debugPrint('percentage ---- $percentage -----');
      }
    }else{
      currentPosition = clientIndex - firstClientIndex + 1;
      debugPrint('-----currentPosition: $currentPosition ------------');
      debugPrint('----------initialPosition: $initialPosition -----------');
      if (initialPosition == 1)
        percentage = 1;
      else {
        double result =
            (initialPosition - currentPosition) / (initialPosition - 1);
          if(result > 1 || result < 0) percentage = 0;
          else percentage = result;
        debugPrint('percentage ---- $percentage -----');
      }
    }
  }

  Future<void> onRefreshCallback() async{
    if(refreshButtonPressed) return;
    refreshButtonPressed = true;
    startLoad();
    if(await Dialogs(context: context).checkConnectionDialog() != true) {
      thereIsConnection = false;
      refreshButtonPressed = false;
      stopLoad();
    }else thereIsConnection = true;
    stopLoad();
    await getUpdatedClientInfo();
    await getUpdatedQueueInfo();
    calculations(true);
    refreshButtonPressed = false;
  }

  @override
  void initState() {
    super.initState();
    debugPrint('the queue id is \'${widget.queue.id}\'');
    Future(() async{
      debugPrint('the queue id is \'${widget.queue.id}\'');
      if(refreshButtonPressed) return;
      debugPrint('button no yet pressed');
      refreshButtonPressed = true;
      startLoad();
      if(await Dialogs(context: context).checkConnectionDialog() != true) {
        thereIsConnection = false;
        refreshButtonPressed = false;
        stopLoad();
      }else thereIsConnection = true;
      stopLoad();
      // Dialogs(context: context).checkConnectionDialog();
      // thereIsConnection = await isThereConnection();
      await getUpdatedClientInfo();
      await getUpdatedQueueInfo();
      calculations(true);
      refreshButtonPressed = false;
    });
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.blue,
      //this is a temporal widget to simulate the addiction of a new client to any given queue
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(widget.queue.name,
        style: TextStyle(
          color: Colors.white
        )),
      ),
      body: ModalProgressHUD(
            inAsyncCall: isLoading,
            color: Colors.white,
            child: MyScreen(context: context, percentage: percentage, currentPosition: currentPosition, onRefreshCallback: onRefreshCallback, timePeriod: timePeriod, mostRecentTransitionTime: mostRecentTransitionTime, isOpen: isOpen, pauseTime: pauseTime, pauseDuration: pauseDuration),
          )
    );
  }
}


class MyScreen extends StatelessWidget {
  final BuildContext context;
  final double percentage;
  final int currentPosition;
  final Function onRefreshCallback;
  final int timePeriod; //time for one session in seconds
  final Timestamp mostRecentTransitionTime;
  final Timestamp pauseTime;
  final int pauseDuration;
  final isOpen;// time for one client to receive a service in seconds
  MyScreen({this.context, this.percentage = 0.3, this.timePeriod = 30, this.currentPosition, this.onRefreshCallback, this.mostRecentTransitionTime, this.isOpen, this.pauseTime, this.pauseDuration});

  String minutes() {
    if (currentPosition != 0) {
      ///calculate the time from the last transition to now
      ///this time can be thought of as the adjustment time interval
      
      int timeSinceLastTransition = DateTime.now().difference(mostRecentTransitionTime.toDate()).inSeconds;

      ///make sure the adjustment time interval i.e. timeSinceLastTransitin is not greater than the timePeriod.
      ///Time since last transition cannot be greate than the timePeriod itself
      if(timeSinceLastTransition >= timePeriod) timeSinceLastTransition = timePeriod;

      ///calculate the total time left
      int time;
      int unAdjustedTime = (currentPosition - 1) * timePeriod;
      //if(unAdjustedTime > timeSinceLastTransition) time = unAdjustedTime - timeSinceLastTransition; //might need to swap this line with the line below it
      if(unAdjustedTime >= timePeriod) time = unAdjustedTime - timeSinceLastTransition;
      else time = 0;
      double minutes = (time - (time/3600).floor() * 3600) / 60;
      String _minutes = minutes.floor().toString();
      if(minutes < 10) return '0' + _minutes;
      else return _minutes;
    }else return '00';
  }

  String hours() {
    if (currentPosition != 0) {
      int time = (currentPosition - 1) * timePeriod;
      double hours = (time/3600);
      String _hours = (hours.floor()).toString();
      if(hours < 10) return '0' + _hours;
      else return _hours;
    }else return '00';
  }

  ///Calculates how long it will take before the queue eventually resumes,
  String resumptionTime() {
    DateTime _pauseTime = pauseTime.toDate();
    DateTime _currentTime = DateTime.now();
    int resumptionTime = pauseDuration - _currentTime.difference(_pauseTime).inSeconds;
    dynamic _hours = (resumptionTime/ 3600).floor();
    dynamic _minutes = ((resumptionTime % 3600) / 60).floor();
    dynamic _seconds = ((resumptionTime % 3600) % 60);
    _hours = (_hours <= 0) ?  '' : '$_hours' + 'h ';
    _minutes = (_minutes <= 0) ?  '' : '$_minutes' + 'm ';
    _seconds = (_seconds <= 0) ?  '' : '$_seconds' + 's';
    return (resumptionTime > 0) ?  _hours + _minutes + _seconds : 'A bit...'; //todo: translate
  }

  Widget pauseCard() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        children: [
          SizedBox(
            height: 10,
          ),
          Center(
            child: Text(
              'PAUSED', //todo: translate
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 25,
              )
            )
          ),
          Center(
              child: Text(
                  'Expected to resume in', //todo: translate
                  style: TextStyle(
                    color: Colors.blue,
                  )
              )
          ),
          Center(
              child: Text(
                  '${resumptionTime()}',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  )
              )
          )
        ]
      )
    );
  }

  Color progressColor() {
    if(percentage == null || percentage <= 0.50) return Colors.white;
    else if(percentage <= 0.75 ) return Colors.orange;
    else if(percentage <= 1.00 ) return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Container(
          color: Colors.blue,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            alignment: Alignment.topCenter,
            children : [
              Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    locale.refreshReminder,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.purple,
                      fontStyle: FontStyle.italic,
                    )
                  ),
                ),
                SizedBox(
                  height: 20
                ),
                // (isOpen == false) ? Center(
                //   child: Text(
                //       'THE QUEUE HAS BEEN PAUSED', //todo: translate this line of code
                //       textAlign: TextAlign.center,
                //       style: TextStyle(
                //         color: Colors.white,
                //         fontStyle: FontStyle.italic,
                //         fontWeight: FontWeight.bold,
                //         fontSize: 20,
                //       )
                //   ),
                // ) : Container(),
                // SizedBox(
                //     height: 20
                // ),
                CircularPercentIndicator(
                  radius: 130.0,
                  lineWidth: 20.0,
                  percent: percentage,
                  animation: true,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      new Text("${(percentage * 100).round()}%",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          )),
                    ],
                  ),
                  progressColor: progressColor(),
                ),
                SizedBox(
                  height: 10,
                ),
                Center(
                    child: Text(locale.myPosition,
                        style: TextStyle(
                          color: Colors.white,
                        )
                    )),
                SizedBox(
                  height: 5,
                ),
                Center(
                  child: Text(
                    '${(currentPosition < 1) ? '--' : '$currentPosition'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                    )
                  )
                ),
                Center(
                    child: Text(locale.estimatedTimeLeft,
                      style: TextStyle(
                        color: Colors.white,
                      )
                    )),
                SizedBox(
                  height: 5,
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${hours()}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                        )
                      ),
                      Text(
                          ':',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 35,
                          )
                      ),
                      Text(
                          '${minutes()}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 35,
                          )
                      )
                    ]
                  ),
                ),
                Center(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            locale.hours,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            )
                        ),
                        SizedBox(
                          width: 30,
                        ),
                        Text(
                            'mins',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            )
                        )
                      ]
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                FlatButton(
                  onPressed: () async{
                    await onRefreshCallback();
                  },
                  child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 50),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                              Radius.circular(20)
                          )
                      ),
                      height: 40,
                      child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 60.0),
                              child: Center(
                                child: Text(
                                    locale.refresh,
                                    style: TextStyle(
                                      color: Colors.blue,
                                    )
                                ),
                              ),
                            )
                        ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                FlatButton(
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (context) => ShowQrCode());
                  },
                  child: Container(
margin: EdgeInsets.symmetric(horizontal: 50),
                      decoration: BoxDecoration(
                          color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(20)
                        )
                      ),
                      height: 40,
                      child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 60.0),
                            child: Center(
                              child: Text(
                                  "QR CODE",
                                  style: TextStyle(
                                    color: Colors.blue,
                                  )
                              ),
                            ),
                          )
                      )
                  ),
                )
              ]
            ),
              isOpen ? Container(child: null) : Column(
                children: [
                  SizedBox(height: 20),
                  pauseCard(),
                ],
              ),],


          )
        ),
      ),
    );
  }
}



