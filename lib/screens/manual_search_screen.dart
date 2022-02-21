import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/data/filter_data.dart';
import 'package:no_queues_client/screens/search_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class ManualSearchScreen extends StatefulWidget {
  @override
  _ManualSearchScreenState createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends State<ManualSearchScreen> {

  int regionValue = 1;
  int divisionValue = 1;
  int subDivisionValue = 1;
  int serviceTypeValue = 1;

  Map<String , String> genFilters() {
    String region = Regions(context).regionsRef[regionValue - 1];
    String division = Divisions().div(region)[divisionValue - 1];
    String subDivision = SubDivisions().subDiv(division)[subDivisionValue - 1];
    String serviceType = ServiceType(context).serviceTypeRef[serviceTypeValue - 1];

    print('------selected filters: region: $region \n division: $division \n subdivision: $subDivision \n serviceType: $serviceType-------');

    return {
      'region' : region,
      'division' : division,
      'sub-division' : subDivision,
      'service-type' : serviceType,
    };
  }

  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appColor,
        title: Text(
            locale.manualSearch,
          style: TextStyle(
            color: Colors.white
          )
        )
      ),
      body:Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(
              locale.selectRegion,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              )
            ),
            DropdownButton(
              menuMaxHeight: 200,
                items: Regions(context).dropdownMenuItems,
                value: regionValue,
              onChanged: (newVal) {
                  if(regionValue != newVal){
                    setState((){
                      regionValue = newVal;
                      divisionValue = 1;
                      subDivisionValue = 1;
                    });
                  }

              },
              hint: Text('Select A region')
            ),
            SizedBox(
              height: 10,
            ),
            Text(
                locale.selectDivision,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                )
            ),
            DropdownButton(
                menuMaxHeight: 200,
              items: Divisions().dropdownMenuItems(Regions(context).regionsRef[regionValue-1]) ,
              value: divisionValue,
              onChanged: (newVal) {
                if(divisionValue != newVal){
                  setState((){
                    divisionValue = newVal;
                    subDivisionValue = 1;
                  });
                }

              },
                hint: Text('Select a division')
            ),
            SizedBox(
              height: 10,
            ),
            Text(
                locale.selectSubD,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                )
            ),
            DropdownButton(
                menuMaxHeight: 200,
              items: SubDivisions().dropdownMenuItems(Divisions().div(Regions(context).regionsRef[regionValue-1])[divisionValue - 1]),
                value: subDivisionValue,
              onChanged: (newVal) {
                if(subDivisionValue != newVal){
                  setState((){
                    subDivisionValue = newVal;
                  });
                }
              },
                hint: Text('Select a subdivision')
            ),
            SizedBox(
              height: 10,
            ),
            Text(
                locale.serviceType,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                )
            ),
            DropdownButton(
                menuMaxHeight: 200,
              items: ServiceType(context).dropdownMenuItems,
              value: serviceTypeValue,
              onChanged: (newVal) {
                if(serviceTypeValue != newVal){
                  setState((){
                    serviceTypeValue = newVal;
                  });
              }
                },
                hint: Text('Select a Service Type')
            ),
            SizedBox(
              height: 10,
            ),
            FlatButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen(genFilters())));
              },
              child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 50),
                  decoration: BoxDecoration(
                      color: Colors.blue,
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
                              locale.search,
                              style: TextStyle(
                                color: Colors.white,
                              )
                          ),
                        ),
                      )
                  )
              ),
            )

          ]
        ),
      )
    );

  }
}

