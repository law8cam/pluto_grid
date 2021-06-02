import '../../pluto_grid.dart';

class ExcelFilters {
  PlutoGridStateManager? stateManager;
  List<PlutoRow?> rows = [];

  ExcelFilters({required this.stateManager}) {
    // rows = stateManager.rows;
    rows = stateManager!.refRows!.originalList;
  }

  List<int> dateFilter({required int filterValue, required List<int> filterIndex, required bool isBefore, String? column}) {
    filterIndex.removeWhere((index) {
      String element = rows[index]!.cells[column]!.value.toString();
      if (element == 'Select All') {
        return false;
      }

      bool isRemove = true;

      if (isBefore) {
        isRemove = DateTime.parse(element).millisecondsSinceEpoch > filterValue;
      } else {
        isRemove = DateTime.parse(element).millisecondsSinceEpoch < filterValue;
      }

      if (isRemove) {
        // checkedList.remove(element);
        return true;
      } else {
        // if (!checkedList.contains(element)) {
        //   checkedList.add(element);
        // }
        return false;
      }
    });

    return filterIndex;
  }

  List<int> numberFilter({required String filterValue, required List<int> filterIndex, required bool isGreater, String? column}) {
    if (double.tryParse(filterValue) != null) {
      double number = double.parse(filterValue);
      filterIndex.removeWhere((index) {
        String element = rows[index]!.cells[column]!.value.toString();

        if (element == 'Select All') {
          return false;
        }

        bool isRemove = true;

        if (isGreater) {
          isRemove = double.parse(element) < number;
        } else {
          isRemove = double.parse(element) > number;
        }

        if (isRemove) {
          // checkedList.remove(element);
          return true;
        } else {
          // if (!checkedList.contains(element)) {
          //   checkedList.add(element);
          // }
          return false;
        }
      });
    }
    return filterIndex;
  }

  List<int> containsFilter({required String filterValue, required List<int> filterIndex, String? column}) {
    List<String> filterList = filterValue.split(',');
    filterList.forEach((element) {
      element = element.trim();
    });

    filterIndex.removeWhere((index) {
      String element = rows[index]!.cells[column]!.value.toString();

      if (element == 'Select All') {
        return false;
      }
      bool isRemove = true;

      // Keep all the items that contain the includes
      filterList.forEach((filter) {
        if (!filter.contains('-')) {
          if (element.toLowerCase().contains(filter.toLowerCase().trim()) && filter.trim() != '') {
            isRemove = false;
          }
        }
      });

      // Then if item is included, check it does not conflict with exclusion
      if (!isRemove) {
        filterList.forEach((filter) {
          if (filter.contains('-')) {
            var exclude = filter.replaceAll('-', '').trim();
            if (element.toLowerCase().contains(exclude.toLowerCase().trim()) && exclude.trim() != '') {
              isRemove = true;
            }
          }
        });
      }
      return isRemove;
    });
    return filterIndex;
  }

  List<int> equalsFilter({required List<String> filterList, required List<int> filterIndex, String? column}) {
    filterIndex.removeWhere((index) {
      String element = rows[index]!.cells[column]!.value.toString();
      if (element == 'Select All') {
        return false;
      }
      bool isRemove = true;
      filterList.forEach((filter) {
        if (element.toLowerCase().trim() == filter.toLowerCase().trim()) {
          isRemove = false;
        }
      });
      return isRemove;
    });
    return filterIndex;
  }
}
