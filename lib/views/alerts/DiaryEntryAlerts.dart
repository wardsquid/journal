import 'package:flutter/material.dart';
import '../../managers/userInfo.dart' as inkling;

/////////////////////////////////////////////
/// CREATE THE DRAWER
/////////////////////////////////////////////
Widget journalDrawer(BuildContext context, Map<String, dynamic> userProfile,
    Function updateJournal, Function changeActiveJournal) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          child: Text(
            'Select a journal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          decoration: BoxDecoration(
            color: Colors.purpleAccent,
          ),
        ),
        for (String title in userProfile['journals_list'])
          journalTile(title, changeActiveJournal),
        ListTile(
          title: Text("Create a new Journal..."),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return createJournal(context, updateJournal);
              },
              barrierDismissible: false,
            );
          },
        ),
      ],
    ),
  );
}

/////////////////////////////////////////////
/// CREATE THE DRAWER TILES
/////////////////////////////////////////////
Widget journalTile(String journalName, Function changeActiveJournal) {
  return new ListTile(
    leading: IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => {print("renaming / sharing whole diary /delete diary")},
    ),
    title: Text(
        journalName == "Personal" ? "$journalName (Default)" : "$journalName"),
    trailing: inkling.currentJournal == journalName ? Icon(Icons.check) : null,
    onTap: () {
      changeActiveJournal(journalName);
    },
  );
}

/////////////////////////////////////////////
/// ALERT TO CREATE A NEW JOURNAL
/////////////////////////////////////////////
Widget createJournal(BuildContext context, Function updateJournal) {
  TextEditingController _diaryController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  return AlertDialog(
    title: Text('Create a new Journal'),
    content: Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        // key: _formKey,
        autofocus: true,
        controller: _diaryController,
        onSaved: (String value) {
          // setState(() {
          //   _name = value;
          // });
          _diaryController.clear();
        },
        decoration: InputDecoration(
          hintText: "Journal's name",
          suffixIcon: IconButton(
            onPressed: () => _diaryController.clear(),
            icon: Icon(Icons.clear),
          ),
        ),
        validator: (value) {
          if (value.isEmpty) {
            return 'Please enter some text';
          } else if (inkling.userProfile["journals_list"].contains(value)) {
            return "A Journal with that name already exists";
          }
          return null;
        },
      ),
    ),
    actions: <Widget>[
      FlatButton(
          child: Text('Add'),
          onPressed: () {
            if (_formKey.currentState.validate()) {
              updateJournal(_diaryController.text);
              _formKey.currentState.save();
              Navigator.of(context).pop();
            }
          }),
      FlatButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          })
    ],
  );
}
