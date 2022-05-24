import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/src/lac/excel_filters.dart';

import '../../pluto_grid.dart';
import 'excel_event.dart';

class EnterIntent extends Intent {}
class EscapeIntent extends Intent {}

enum FilterType {
  contains,
  greater,
  lesser,
  before,
  after,
}

// ignore: must_be_immutable
class ExcelMenu extends StatefulWidget {
  BuildContext? context;
  PlutoGridStateManager? stateManager;
  PlutoColumn? column;

  ExcelMenu({required this.context, this.stateManager, required this.column});

  @override
  _ExcelMenuState createState() => _ExcelMenuState();
}

class _ExcelMenuState extends State<ExcelMenu> {
  List<String> filterItems = [];
  List<String> filterItemsFormatted = [];
  List<String> filterIndex = [];
  late ExcelFilters excelFilters = ExcelFilters(stateManager: widget.stateManager!);

  late List<PlutoRow?> rows = widget.stateManager!.refRows!.originalList;

  bool displayAll = false;

  TextEditingController containsController = TextEditingController();
  TextEditingController greaterController = TextEditingController();
  TextEditingController lesserController = TextEditingController();

  TextEditingController afterMinController = TextEditingController();
  TextEditingController afterHourController = TextEditingController();
  TextEditingController afterDayController = TextEditingController();

  TextEditingController beforeMinController = TextEditingController();
  TextEditingController beforeHourController = TextEditingController();
  TextEditingController beforeDayController = TextEditingController();

  FocusNode mainFocusNode = FocusNode();

  late String currentColumn = widget.column!.field;
  late bool isStart = currentColumn.toLowerCase().contains('start');

  int beforeUnix = 0;
  int afterUnix = 0;

  late Map<String, TextEditingController> controllerMap = {
    'Contains': containsController,
    'Greater': greaterController,
    'Lesser': lesserController,
    'BeforeMin': beforeMinController,
    'BeforeHour': beforeHourController,
    'BeforeDay': beforeDayController,
    'AfterMin': afterMinController,
    'AfterHour': afterHourController,
    'AfterDay': afterDayController,
  };

  late Map<String, Map<String, String>> filterData = widget.stateManager!.filtersNew;

  Map<String, bool> checked = {};
  List<String> checkedList = [];

  // List<String> indexCheckedList = [];
  late PlutoColumnType? columnType = widget.column!.type;
  var filter = '';
  int fullCount = 0;

  List<String> sortList(List<String> listToSort) {
    if (columnType.isNumber) {
      listToSort.sort((a, b) => double.parse(a).compareTo(double.parse(b)));
    } else if (columnType.isDate) {
      // listToSort.sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(a)));
      listToSort.sort((a, b) {
        return DateTime.parse(a).compareTo(DateTime.parse(b));
      });
    } else {
      listToSort.sort((a, b) => a.compareTo(b));
    }
    return listToSort;
  }

  /// Applies the filter rows using text and other column data
  List<String> filterRows({bool reset = true, bool initial = false}) {
    // Why doing this?
    if (reset) {
      resetFilter(initial: initial);
    }

    // Filter using data from other columns
    if (!displayAll) {
      // Apply other saved filters
      filterData.forEach((column, filterMap) {
        // Use the text field to filter the current column
        if (column != currentColumn) {
          int beforeUnix = 0;
          int afterUnix = 0;
          filterMap.forEach((key, value) {
            if (key == 'Contains') {
              filterIndex = excelFilters.containsFilter(filterValue: value, filterIndex: filterIndex, column: column);
            } else if (key == 'Greater') {
              filterIndex = excelFilters.numberFilter(filterValue: value, filterIndex: filterIndex, isGreater: true, column: column);
            } else if (key == 'Lesser') {
              filterIndex = excelFilters.numberFilter(filterValue: value, filterIndex: filterIndex, isGreater: false, column: column);
            } else if (key == 'BeforeMin') {
              beforeUnix += (double.parse(value) * 60 * 1000).toInt();
            } else if (key == 'BeforeHour') {
              beforeUnix += (double.parse(value) * 60 * 60 * 1000).toInt();
            } else if (key == 'BeforeDay') {
              beforeUnix += (double.parse(value) * 24 * 60 * 60 * 1000).toInt();
            } else if (key == 'AfterMin') {
              afterUnix += (double.parse(value) * 60 * 1000).toInt();
            } else if (key == 'AfterHour') {
              afterUnix += (double.parse(value) * 60 * 60 * 1000).toInt();
            } else if (key == 'AfterDay') {
              afterUnix += (double.parse(value) * 24 * 60 * 60 * 1000).toInt();
            } else if (key == 'Selected') {
              List<String> stringList = [];
              jsonDecode(value).forEach((dynamic element) {
                stringList.add(element.toString());
              });
              filterIndex = excelFilters.equalsFilter(filterList: stringList, filterIndex: filterIndex, column: column);
            }
          });

          if (beforeUnix != 0) {
            filterIndex = excelFilters.dateFilter(
              filterValue: beforeUnix,
              filterIndex: filterIndex,
              isBefore: true,
              isFuture: isStart ? false : true,
              column: column,
            );
          }

          if (afterUnix != 0) {
            filterIndex = excelFilters.dateFilter(
              filterValue: afterUnix,
              filterIndex: filterIndex,
              isBefore: false,
              isFuture: isStart ? false : true,
              column: column,
            );
          }
        }
      });
    }

    // Filter using text fields
    if (containsController.value.text.isNotEmpty) {
      filterIndex = excelFilters.containsFilter(filterValue: containsController.value.text, filterIndex: filterIndex, column: currentColumn);
    }

    if (columnType.isDate) {
      if (getUnix(isBefore: false) != 0) {
        filterIndex = excelFilters.dateFilter(
          filterValue: getUnix(isBefore: false),
          filterIndex: filterIndex,
          isBefore: false,
          isFuture: isStart ? false : true,
          column: currentColumn,
        );
      }

      if (getUnix(isBefore: true) != 0) {
        filterIndex = excelFilters.dateFilter(
          filterValue: getUnix(isBefore: true),
          filterIndex: filterIndex,
          isBefore: true,
          isFuture: isStart ? false : true,
          column: currentColumn,
        );
      }
    }

    if (columnType.isNumber) {
      if (greaterController.value.text.isNotEmpty) {
        filterIndex = excelFilters.numberFilter(filterValue: greaterController.value.text, filterIndex: filterIndex, isGreater: true, column: currentColumn);
      }

      if (lesserController.value.text.isNotEmpty) {
        filterIndex = excelFilters.numberFilter(filterValue: lesserController.value.text, filterIndex: filterIndex, isGreater: false, column: currentColumn);
      }
    }

    filterIndex = filterIndex.toSet().toList();
    filterIndex.sort((a, b) => a.compareTo(b));

    if (filterItems.length == 1) {
      filterItems = [];
      checkedList = [];
    }

    filterItems = [];

    // Map<String, String> formattedMap = <String, String> {};
    // filterIndex.forEach((index) {
    //   PlutoRow? row = excelFilters.rowFromKey(index);
    //   var rowValue = row!.cells[currentColumn]!.value.toString();
    //   var rowFormatted = widget.column!.formattedValueForDisplay(rowValue);
    //   formattedMap.putIfAbsent(rowFormatted, () => rowValue);
    //
    //   // filterItems.add(row!.cells[currentColumn]!.value.toString());
    // });
    // filterItems += formattedMap.values.toList();

    filterIndex.forEach((index) {
      PlutoRow? row = excelFilters.rowFromKey(index);
      filterItems.add(row!.cells[currentColumn]!.value.toString());
      // filterItems.add(rows[index]!.cells[currentColumn]!.value.toString());
    });

    if (displayAll && widget.column!.allItems.isNotEmpty) {
      var additionalItems = excelFilters.containsFilterString(
          filterValue: containsController.value.text, itemsToFilter: []..addAll(widget.column!.allItems), column: currentColumn);
      filterItems.addAll(additionalItems);
    }

    filterItems = filterItems.toSet().toList();
    filterItems = sortList(filterItems);

    filterItems.insert(0, 'Select All');

    fullCount = filterItems.length;

    return filterItems;
  }

  String formatDate(int unix) {
    if (unix == 0) {
      return '';
    }
    String date = DateTime.fromMillisecondsSinceEpoch(unix).toString();
    String formatted = widget.column!.formattedValueForDisplay(date);
    return formatted;
  }

  int getUnix({bool isBefore = false, bool isStart = false, bool isDelta = true}) {
    int dayUnix = 0;
    int hourUnix = 0;
    int minuteUnix = 0;

    String dayString = isBefore ? beforeDayController.value.text : afterDayController.value.text;
    String hourString = isBefore ? beforeHourController.value.text : afterHourController.value.text;
    String minuteString = isBefore ? beforeMinController.value.text : afterMinController.value.text;

    try {
      if (double.tryParse(dayString) != null) {
        dayUnix = (double.parse(dayString) * 24 * 60 * 60 * 1000).toInt();
      }

      if (double.tryParse(hourString) != null) {
        hourUnix = (double.parse(hourString) * 60 * 60 * 1000).toInt();
      }

      if (double.tryParse(minuteString) != null) {
        minuteUnix = (double.parse(minuteString) * 60 * 1000).toInt();
      }
    } catch (e) {
      return 0;
    }

    int delta = dayUnix + hourUnix + minuteUnix;

    if (delta == 0) {
      return 0;
    }

    int unix = DateTime.now().millisecondsSinceEpoch + delta;

    if (isStart) {
      unix = DateTime.now().millisecondsSinceEpoch - delta;
    }

    if (isDelta) {
      return delta;
    } else {
      return unix;
    }
  }

  void resetFilter({bool initial = false}) {
    filterItems = [];

    // Populate with the original/full list
    rows.forEach((row) {
      filterItems.add(row!.cells[widget.column!.field]!.value.toString());
      // filterIndex.add(row.sortIdx as int);
      filterIndex.add(row.key.toString());
    });

    // Remove duplicates and sort
    filterItems = filterItems.toSet().toList();
    filterItems = sortList(filterItems);

    fullCount = filterItems.length;

    // If initial then use visible rows to set checked items
    if (initial) {
      // Use visible rows to set if checked
      widget.stateManager!.rows.forEach((row) {
        checkedList.add(row!.cells[currentColumn]!.value.toString());
      });

      checkedList = checkedList.toSet().toList();

      // Apply all filters
      // filterData.forEach((column, value) {});

      // Apply other column filters
      if (filterData.containsKey(currentColumn) && !displayAll) {
        Map<String, String>? filters = filterData[currentColumn];

        // Add filter data to text fields
        filters!.forEach((key, value) {
          if (key != 'Selected') {
            controllerMap[key]!.text = value;
          }
        });

        // Filter the rows, to apply other rows or previous filtering
        // This is loosing the un-checked items
      }

      filterRows(reset: false);
    } else {
      // if not initial then check all items
      // this is when contains is undone
      checkedList = [];
      checkedList.addAll(filterItems);
    }

    // Add select all to top
    if (!filterItems.contains('Select All')) {
      filterItems.insert(0, 'Select All');
    }

    if (!checkedList.contains('Select All') && checkedList.isNotEmpty) {
      checkedList.add('Select All');
    }
  }

  bool? getShowAllChecked() {
    bool allChecked = true;
    bool noneChecked = true;

    filterItems.forEach((element) {
      if (element != 'Select All') {
        if (checkedList.contains(element)) {
          noneChecked = false;
        } else {
          allChecked = false;
        }
      }
    });

    if (allChecked) {
      return true;
    } else if (noneChecked) {
      return false;
    } else {
      return null;
    }

    // if (checkedList.length == filterItems.length) {
    //   // All Selected
    //   return true;
    // } else if (checkedList.isEmpty) {
    //   // Non Selected
    //   return false;
    // } else {
    //   // Some Selected
    //   return null;
    // }
  }

  Map<String, Map<String, String>> saveFilter() {
    // Update only this column

    Map<String, String> saved = {};
    controllerMap.forEach((key, controller) {
      if (controller.value.text.isNotEmpty) {
        saved[key] = controller.value.text;
      }
    });

    // Selected
    if (getShowAllChecked() == null) {
      saved['Selected'] = jsonEncode(checkedList);
    }

    if (saved.isNotEmpty) {
      filterData[currentColumn] = saved;
    } else {
      filterData.remove(currentColumn);
    }

    return filterData;
  }

  void saveAndClose() {
    Map<String, Map<String, String>> newData = saveFilter();
    widget.stateManager!.setFiltersNewColumns(newData.keys.toList());

    // Resize to trigger column filter icon
    widget.stateManager!.resizeColumn(widget.stateManager!.columns[0].key, 0.00001);

    // Apply filter to UI
    widget.stateManager!.setFilter((element) {
      // if (!filterIndex.contains(element!.sortIdx)) {
      if (!filterIndex.contains(element!.key.toString())) {
        return false;
      } else if (!checkedList.contains(element.cells[currentColumn]!.value.toString())) {
        return false;
      } else {
        return true;
      }
    });
    widget.stateManager!.setFiltersNew(newData);

    if (newData.isEmpty) {
      // Send data cleared event
    }

    widget.stateManager!.eventManager!.addEvent(ExcelSavedEvent());
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    resetFilter(initial: true);
  }

  @override
  Widget build(BuildContext context) {
    if (filterItems.isEmpty) {
      filterRows();
    }

    filterItemsFormatted = [];
    filterItems.forEach((element) {
      if(element == 'Select All'){
        filterItemsFormatted.add('Select All');
      }else{
        filterItemsFormatted.add(widget.column!.formattedValueForDisplay(element));
      }
    });

    Color textColor = Theme.of(context).textTheme.bodyText2!.color ?? Colors.black;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): EnterIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): EscapeIntent(),
      },
      child: Actions(
        actions: {
          EnterIntent: CallbackAction<EnterIntent>(onInvoke: (intent) => saveAndClose()),
          EscapeIntent: CallbackAction<EscapeIntent>(onInvoke: (intent) => Navigator.of(context).pop())
        },
        child: Focus(
          autofocus: true,
          child: Container(
            width: 600,
            height: 1000,
            // color: Colors.grey[200],
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.all(12),
            // margin: EdgeInsets.all(5),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 18, right: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  resetFilter();
                                  // Clear filter data
                                  widget.stateManager!.setFiltersNew({});
                                  filterData = {};

                                  // Clear all text fields
                                  controllerMap.forEach((key, value) {
                                    value.text = '';
                                  });
                                });
                              },
                              child: Container(
                                height: 50,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.filter_alt,
                                      color: textColor,
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Text(
                                      'Remove All Filters',
                                      style: TextStyle(fontSize: 16, color: textColor),
                                    ),
                                  ],
                                ),
                              )),

                          // if(widget.column.)
                          Container(
                            width: 200,
                            child: CheckboxListTile(
                              tristate: false,
                              title: const Text('Display All'),
                              value: displayAll,
                              onChanged: (value) {
                                setState(() {
                                  displayAll = value!;
                                  filterRows(initial: true);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                          onPressed: () {
                            widget.stateManager!.hideColumn(widget.column!.key, true);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 50,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.hide_image,
                                  color: textColor,
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  'Hide Column',
                                  style: TextStyle(fontSize: 16, color: textColor),
                                ),
                              ],
                            ),
                          )),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.stateManager!.showSetColumnsPopup(context);
                        },
                        child: Container(
                          height: 50,
                          child: Row(
                            children: [
                              Icon(Icons.view_column_outlined, color: textColor),
                              const SizedBox(
                                width: 20,
                              ),
                              Text(
                                'Set Columns',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Card(
                  color: Theme.of(context).dialogBackgroundColor,
                  child: Container(
                    padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                    child: Column(
                      children: [
                        TextField(
                          controller: containsController,
                          decoration: const InputDecoration(labelText: 'Contains'),
                          keyboardType: columnType.isNumber ? TextInputType.number : TextInputType.text,
                          inputFormatters: columnType.isNumber ? [FilteringTextInputFormatter.allow(RegExp('[0-9.]'))] : null,
                          onEditingComplete: () {
                            mainFocusNode.requestFocus();
                          },
                          onChanged: (value) {
                            setState(() {
                              filterRows();
                            });
                          },
                        ),
                        if (columnType.isNumber) const SizedBox(height: 10),

                        // #,##0.00
                        if (columnType.isNumber)
                          TextField(
                            controller: greaterController,
                            decoration: const InputDecoration(labelText: 'Greater Than'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.]'))],
                            onEditingComplete: () {
                              mainFocusNode.requestFocus();
                            },
                            onChanged: (value) {
                              setState(() {
                                filterRows();
                              });
                            },
                          ),
                        if (columnType.isNumber) const SizedBox(height: 10),
                        if (columnType.isNumber)
                          TextField(
                            controller: lesserController,
                            decoration: const InputDecoration(labelText: 'Less Than'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.]'))],
                            onEditingComplete: () {
                              mainFocusNode.requestFocus();
                            },
                            onChanged: (value) {
                              setState(() {
                                filterRows();
                              });
                            },
                          ),
                        if (columnType.isDate)
                          Container(
                            // width: 500,
                            // height: 300,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 150,
                                  child: columnType.isDate
                                      ? ListTile(
                                          minLeadingWidth: 0,
                                          title: Text(
                                            currentColumn.toLowerCase().contains('start') ? 'Started Before' : 'Ending Before',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                          subtitle: Text(formatDate(getUnix(isBefore: true, isStart: isStart, isDelta: false))),
                                        )
                                      : Text(
                                          currentColumn.toLowerCase().contains('start') ? 'Started Before' : 'Ending Before',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                ),

                                // Container(
                                //   width: 150,
                                //   child: Text(
                                //     currentColumn.toLowerCase().contains('start') ? 'Started Before' : 'Ending Before',
                                //     style: const TextStyle(fontSize: 16),
                                //   ),
                                // ),
                                Container(
                                  width: 100,
                                  child: TextField(
                                    controller: beforeDayController,
                                    decoration: const InputDecoration(labelText: 'Days'),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    keyboardType: TextInputType.number,
                                    onEditingComplete: () {
                                      mainFocusNode.requestFocus();
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        // filter = value;
                                        filterRows();
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  child: TextField(
                                    controller: beforeHourController,
                                    decoration: const InputDecoration(labelText: 'Hours'),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    keyboardType: TextInputType.number,
                                    onEditingComplete: () {
                                      mainFocusNode.requestFocus();
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        // filter = value;
                                        filterRows();
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  child: TextField(
                                    controller: beforeMinController,
                                    decoration: const InputDecoration(labelText: 'Minutes'),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    keyboardType: TextInputType.number,
                                    onEditingComplete: () {
                                      mainFocusNode.requestFocus();
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        // filter = value;
                                        filterRows();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (columnType.isDate)
                          Container(
                            // width: 500,
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 150,
                                  child: columnType.isDate
                                      ? ListTile(
                                          minLeadingWidth: 0,
                                          title: Text(
                                            currentColumn.toLowerCase().contains('start') ? 'Started After' : 'Ending After',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                          subtitle: Text(formatDate(getUnix(isBefore: false, isStart: isStart, isDelta: false))),
                                        )
                                      : Text(
                                          currentColumn.toLowerCase().contains('start') ? 'Started After' : 'Ending After',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                ),
                                Container(
                                  width: 100,
                                  child: TextField(
                                    controller: afterDayController,
                                    decoration: const InputDecoration(labelText: 'Days'),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    keyboardType: TextInputType.number,
                                    onEditingComplete: () {
                                      mainFocusNode.requestFocus();
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        // filter = value;
                                        filterRows();
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  child: TextField(
                                    controller: afterHourController,
                                    decoration: const InputDecoration(labelText: 'Hours'),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    keyboardType: TextInputType.number,
                                    onEditingComplete: () {
                                      mainFocusNode.requestFocus();
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        // filter = value;
                                        filterRows();
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  child: TextField(
                                    controller: afterMinController,
                                    decoration: const InputDecoration(labelText: 'Minutes'),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    keyboardType: TextInputType.number,
                                    onEditingComplete: () {
                                      mainFocusNode.requestFocus();
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        // filter = value;
                                        filterRows();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Card(
                    color: Theme.of(context).dialogBackgroundColor,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      // height: columnType.isText ? MediaQuery.of(context).size.height - 446 : MediaQuery.of(context).size.height - 574,
                      color: Theme.of(context).dialogBackgroundColor,
                      child: Scrollbar(
                        isAlwaysShown: true,
                        showTrackOnHover: true,
                        child: ListView.builder(
                          itemCount: filterItems.length,
                          itemBuilder: (context, index) {

                            // Hide row?
                            // If formatted row has already been added then hide
                            bool showRow = true;
                            var formattedValue = widget.column!.formattedValueForDisplay(filterItems[index]);
                            // var formattedValue = widget.column!.renderer();
                            if(index != 0 && filterItemsFormatted.sublist(0,index).contains(formattedValue)){
                              showRow = false;
                            }
                            // print(showRow);
                            return Visibility(
                              visible: showRow,
                              child: Container(
                                width: 400,
                                // height: 30,
                                child: Column(
                                  children: [
                                    const Divider(
                                      height: 1,
                                    ),
                                    Visibility(
                                      child: CheckboxListTile(
                                        tristate: filterItems[index] == 'Select All' ? true : false,
                                        activeColor: Theme.of(context).brightness == Brightness.dark ? Colors.blue : null,
                                        // title: Text(filterItems[index]),
                                        title: Text(filterItems[index] == 'Select All' ? 'Select All' : widget.column!.formattedValueForDisplay(filterItems[index])),
                                        // title: Text(filterItems[index] == 'Select All' ? 'Select All' : widget.column!.rend,
                                        value: filterItems[index] == 'Select All' ? getShowAllChecked() : checkedList.contains(filterItems[index]),
                                        onChanged: (value) {
                                          var title = filterItems[index];
                                          if (title == 'Select All') {
                                            setState(() {
                                              // If Select All is in checkedLists
                                              // Clear check List
                                              if (checkedList.contains(title)) {
                                                // then set as true
                                                checkedList = [];
                                              } else {
                                                checkedList = [];
                                                checkedList.addAll(filterItems);
                                              }
                                            });
                                          } else {
                                            setState(() {

                                              // Get title of all that match formatted
                                              var formattedValue = widget.column!.formattedValueForDisplay(title);
                                              filterItems.forEach((element) {
                                                var elementFormattedValue = widget.column!.formattedValueForDisplay(element);
                                                if(formattedValue == elementFormattedValue){
                                                  checked[element] = value!;
                                                  if (value && !checkedList.contains(element)) {
                                                    checkedList.add(element);
                                                  } else {
                                                    checkedList.remove(element);
                                                  }
                                                }
                                              });


                                              // checked[title] = value!;
                                              // if (value && !checkedList.contains(title)) {
                                              //   checkedList.add(title);
                                              // } else {
                                              //   checkedList.remove(title);
                                              // }
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                            alignment: Alignment.center,
                            width: 100,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 20),
                            ))),
                    Text('${resultCount()} items'),
                    ElevatedButton(
                        onPressed: () {
                          saveAndClose();
                        },
                        child: Container(
                            alignment: Alignment.center,
                            width: 100,
                            child: const Text(
                              'Done',
                              style: TextStyle(fontSize: 20),
                            ))),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String resultCount() {
    int count = 0;
    widget.stateManager!.refRows!.forEach((element) {
      if (filterIndex.contains(element!.key.toString()) && checkedList.contains(element.cells[currentColumn]!.value.toString())) {
        count++;
      }
    });
    return count.toString();
  }
}
