import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';
import 'package:no_queues_client/my_widgets/searched_queue_tile.dart';
import 'package:no_queues_client/context.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';


class SearchScreen extends StatefulWidget {
  final Map<String, String> filters;
  SearchScreen(this.filters);
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Queue> searchedQueueMans = [];
  bool isLoading = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    print('-----search screen initstate executed------');
    Future(()async{
      await getQueueMans();});
    myContext.updateContext(context);
  }

  void startLoading(){
    setState(() {
      isLoading = true;
    });
  }

  void stopLoading() {
    setState(() {
      isLoading  = false;
    });

  }

  Widget searchView() {
    print('------${searchedQueueMans.length}------');
    if(searchedQueueMans.isNotEmpty){
      print('-----searched queues isn\'t null-----');
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start ,
      children: [
        SizedBox(height: 20),
        Flexible(
          child: Container(
              child: ListView.builder(
                  itemCount: searchedQueueMans.length,
                  itemBuilder: (context, index) {
                    return SearchedQueueTile(searchedQueueMans[index]);
                  })
          ),
        ),
      ],
    ) ;
    }
    else {
      print('-----Searched Queue mans is empty-----');
      return
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal : 8.0),
          child: Text(
            AppLocalizations.of(context).noSearchMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
            )
          ),
        ));
    }
  }



  Future<void> getQueueMans () async{
    startLoading();
    print('bottom was pressed');
    try {
      Map services = {};
      var filterDoc = await firestore.collection('filter_docs').where('filter' , isEqualTo: widget.filters).limit(1).get();
      if(filterDoc.docs.isNotEmpty) {
        String filterId = filterDoc.docs[0]['id'];
        var servicesOfFilter = await firestore.collection('filter_docs').doc(filterId).collection('services').get();
        if(servicesOfFilter.docs.isNotEmpty) {
          for(var serviceDoc in servicesOfFilter.docs){
            services.addAll(serviceDoc['services']);
          }

          for(String serviceId in services.keys.toList()) {
            Queue newQueue = Queue();
            newQueue.setId(serviceId);
            newQueue.setName(services[serviceId]);
            setState(() {
              searchedQueueMans.add(newQueue);
            });
          }
        }
      }

    } catch(e) {
      print(e);
      }
      stopLoading();
    }

  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context);
    print('-----search screen build method executed------');
    myContext.updateContext(context);
    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(locale.searchResults,
          style: TextStyle(
            color: Colors.white,
          )),
        ),
        body: searchView()
      ),
    );
  }
}
