import 'dart:convert';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:intl/intl.dart';


import '../../dummy_data/development.dart';
import '../../widget/pluto_example_button.dart';
import '../../widget/pluto_example_screen.dart';

class ColumnFilteringScreen extends StatefulWidget {
  static const routeName = 'feature/column-filtering';

  @override
  _ColumnFilteringScreenState createState() => _ColumnFilteringScreenState();
}

class _ColumnFilteringScreenState extends State<ColumnFilteringScreen> {
  List<PlutoColumn>? columns;

  List<PlutoRow>? rows;

  late PlutoGridStateManager stateManager;

  @override
  void initState() {
    super.initState();

    columns = [
      PlutoColumn(
        title: 'Text',
        field: 'text',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
        title: 'Number',
        field: 'number',
        type: PlutoColumnType.number(format: '#,###.##'),
        // formatter: (value) => value,
        formatter: (dynamic v) {
          return '£${double.parse(v.toString()).toStringAsFixed(2)}';
        },
      ),
      PlutoColumn(
        title: 'Start Date',
        field: 'start date',
        // type: PlutoColumnType.date(format: 'dd-MMM-yy',),
        type: PlutoColumnType.date(),
        formatter: (dynamic v) {
          DateTime date = DateTime.parse(v.toString());
          DateFormat format = DateFormat('dd-MMM-yy');
          String dateString = format.format(date);
          return dateString;
        },
      ),
      PlutoColumn(
        title: 'End Date',
        field: 'end date',
        // type: PlutoColumnType.date(format: 'dd-MMM-yy',),
        type: PlutoColumnType.date(),
        formatter: (dynamic v) {
          DateTime date = DateTime.parse(v.toString());
          DateFormat format = DateFormat('dd-MMM-yy');
          String dateString = format.format(date);
          return dateString;
        },
      ),
      PlutoColumn(
        title: 'Disable',
        field: 'disable',
        type: PlutoColumnType.text(),
        enableFilterMenuItem: false,
      ),
      PlutoColumn(
        title: 'Select',
        field: 'select',
        type: PlutoColumnType.select(<String>['A', 'B', 'C', 'D', 'E', 'F']),
        allItems: ['Red', 'Blue', 'Green'],
      ),
    ];

    rows = DummyData.rowsByColumns(length: 30, columns: columns);
  }

  @override
  Widget build(BuildContext context) {
    return PlutoExampleScreen(
      title: 'Column filtering',
      topTitle: 'Column filtering',

      // topContents: [
      //   const Text('Filter rows by setting filters on columns.'),
      //   const SizedBox(
      //     height: 10,
      //   ),
      //   const Text(
      //       'Select the SetFilter menu from the menu that appears when you tap the icon on the right of the column'),
      //   const Text(
      //       'If the filter is set to all or complex conditions, TextField under the column is deactivated.'),
      //   const Text(
      //       'Also, like the Disable column, if enableFilterMenuItem is false, it is excluded from all column filtering conditions.'),
      //   const Text(
      //       'In the case of the Select column, it is a custom filter that can filter multiple filters with commas. (ex: a,b,c)'),
      //   const SizedBox(
      //     height: 10,
      //   ),
      //   const Text('Check out the source to add custom filters.'),
      // ],
      topButtons: [
        PlutoExampleButton(
          url:
              'https://github.com/bosskmk/pluto_grid/blob/master/example/lib/screen/feature/column_filtering_screen.dart',
        ),
        const SizedBox(width: 50),
        TextField(onChanged: (value) {setState(() {

        });},),
        const SizedBox(width: 50),

        ElevatedButton(onPressed: () {

          List<String> selected = ['Amber', "Antonio's Pizza", '21 Club', '241 Pizza', 'BOOF'];

          stateManager.applyFiltersNew({'text': {'Selected': jsonEncode(selected)}});

        }, child: const Text('Testing', style: TextStyle(fontSize: 30),))
      ],
      body: Container(
        child: PlutoGrid(
          columns: columns,
          rows: rows,
          onLoaded: (PlutoGridOnLoadedEvent event) {

            stateManager = event.stateManager!;
            stateManager.addListener(() {
              // print('State Listener');
            });

            stateManager.eventManager!.listener((event) {
              // print('Event Listener');
            });

          },
          onChanged: (PlutoGridOnChangedEvent event) {
            print(event);
          },
          configuration: PlutoGridConfiguration(

            scrollbarConfig: const PlutoGridScrollbarConfig(
              isAlwaysShown: true,
              draggableScrollbar: true,
              scrollbarThickness: 8

            ),
            /// If columnFilterConfig is not set, the default setting is applied.
            ///
            /// Return the value returned by resolveDefaultColumnFilter through the resolver function.
            /// Prevents errors returning filters that are not in the filters list.
            // columnFilterConfig: PlutoGridColumnFilterConfig(
            //   filters: const [
            //     ...FilterHelper.defaultFilters,
            //     // custom filter
            //     ClassYouImplemented(),
            //   ],
            //   resolveDefaultColumnFilter: (column, resolver) {
            //     if (column.field == 'text') {
            //       return resolver<PlutoFilterTypeContains>() as PlutoFilterType;
            //     } else if (column.field == 'number') {
            //       return resolver<PlutoFilterTypeGreaterThan>()
            //           as PlutoFilterType;
            //     } else if (column.field == 'date') {
            //       return resolver<PlutoFilterTypeLessThan>() as PlutoFilterType;
            //     } else if (column.field == 'select') {
            //       return resolver<ClassYouImplemented>() as PlutoFilterType;
            //     }
            //
            //     return resolver<PlutoFilterTypeContains>() as PlutoFilterType;
            //   },
            // ),
          ),
        ),
      ),
    );
  }
}

class ClassYouImplemented implements PlutoFilterType {
  String get title => 'Custom contains';

  get compare => ({
        required String? base,
        required String? search,
        required PlutoColumn? column,
      }) {
        var keys = search!.split(',').map((e) => e.toUpperCase()).toList();

        return keys.contains(base!.toUpperCase());
      };

  const ClassYouImplemented();
}
