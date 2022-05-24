import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  static const routeName = 'test_screen';

  var filterItems = ["Black", "Blue", "Yellow", "Red", "Green", "Pink"];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          padding: EdgeInsets.all(30),
          margin: EdgeInsets.all(10),
          child: Column(
            children: [
              ListTile(
                title: Text("Sort Large to Small"),
                leading: Icon(Icons.sort),
              ),
              ListTile(
                title: Text("Sort Small to Large"),
                leading: Icon(Icons.sort),
              ),
              ListTile(
                title: Text("Remove Filter"),
                leading: Icon(Icons.filter_alt),
              ),
              ListTile(
                title: Text("Hide Row"),
                leading: Icon(Icons.hide_image),
              ),
              TextField(
                decoration: InputDecoration(labelText: "Filter for"),
              ),
              Container(
                height: 300,
                child: ListView.builder(
                  itemCount: filterItems.length,
                  itemBuilder: (context, index) => CheckboxListTile(
                    title: Text(filterItems[index]),
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
