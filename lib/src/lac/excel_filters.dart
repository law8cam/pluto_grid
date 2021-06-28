import '../../pluto_grid.dart';

class ExcelFilters {
  PlutoGridStateManager? stateManager;
  List<PlutoRow?> rows = [];

  ExcelFilters({required this.stateManager}) {
    // rows = stateManager.rows;
    rows = stateManager!.refRows!.originalList;
  }

  PlutoRow? rowFromKey(String key){
    return rows.firstWhere((element) => element!.key.toString() == key);
  }


  List<String> dateFilter({required int filterValue, required List<String> filterIndex, required bool isBefore, bool isFuture = true, String? column}) {

    if(isFuture){
      filterValue = DateTime.now().millisecondsSinceEpoch + filterValue;
    }else{
      filterValue = DateTime.now().millisecondsSinceEpoch - filterValue;
    }

    filterIndex.removeWhere((index) {
      String element = rowFromKey(index)!.cells[column]!.value.toString();
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
        return true;
      } else {
        return false;
      }
    });

    return filterIndex;
  }

  List<String> numberFilter({required String filterValue, required List<String> filterIndex, required bool isGreater, String? column}) {
    if (double.tryParse(filterValue) != null) {
      double number = double.parse(filterValue);
      filterIndex.removeWhere((index) {
        String element = rowFromKey(index)!.cells[column]!.value.toString();

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

  List<String> containsFilter({required String filterValue, required List<String> filterIndex, String? column}) {
    List<String> filterList = filterValue.split(',');

    filterList.removeWhere((element) => element.trim().replaceAll('-', '') == '');
    
    bool excludeOnly = true;
    filterList.forEach((element) {
      element = element.trim();
      if(!element.contains('-')){
        excludeOnly = false;
      }
    });

    filterIndex.removeWhere((index) {
      String element = rowFromKey(index)!.cells[column]!.value.toString();

      if (element == 'Select All') {
        return false;
      }
      bool isRemove = true;

      if(excludeOnly){
        isRemove = false;
      }else {
        // Keep all the items that contain the includes
        filterList.forEach((filter) {
          if (!filter.contains('-')) {
            if (element.toLowerCase().contains(filter.toLowerCase().trim()) && filter.trim() != '') {
              isRemove = false;
            }
          }
        });
      }

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

  List<String> containsFilterString({required String filterValue, required List<String> itemsToFilter, String? column}) {
    List<String> filterList = filterValue.split(',');

    filterList.removeWhere((element) => element.trim().replaceAll('-', '') == '');

    bool excludeOnly = true;
    filterList.forEach((element) {
      element = element.trim();
      if(!element.contains('-')){
        excludeOnly = false;
      }
    });

    itemsToFilter.removeWhere((element) {

      if (element == 'Select All') {
        return false;
      }
      bool isRemove = true;

      if(excludeOnly){
        isRemove = false;
      }else {
        // Keep all the items that contain the includes
        filterList.forEach((filter) {
          if (!filter.contains('-')) {
            if (element.toLowerCase().contains(filter.toLowerCase().trim()) && filter.trim() != '') {
              isRemove = false;
            }
          }
        });
      }

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
    return itemsToFilter;
  }

  List<String> equalsFilter({required List<String> filterList, required List<String> filterIndex, String? column}) {
    filterIndex.removeWhere((index) {
      String element = rowFromKey(index)!.cells[column]!.value.toString();

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
