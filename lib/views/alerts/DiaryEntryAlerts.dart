import 'package:flutter/material.dart';
import '../../managers/userInfo.dart' as inkling;

/////////////////////////////////////////////
/// CREATE THE DRAWER
/////////////////////////////////////////////
Widget journalDrawer(
    BuildContext context,
    Map<String, dynamic> userProfile,
    Function updateJournal,
    Function changeActiveJournal,
    Function updateSharingList,
    Function updateJournalSharingInDB,
    Function updateJournalsListName,
    Function deleteJournal) {
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
            color: Color(0xFFf2296a),
          ),
        ),
        for (String title in userProfile['journals_list'])
          journalTile(context, title, changeActiveJournal, updateSharingList,
              updateJournalSharingInDB, updateJournalsListName, deleteJournal),
        ListTile(
          title: Text("Create a new journal..."),
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
        ListTile(
          title: Text("Close"),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

/////////////////////////////////////////////
/// CREATE THE DRAWER TILES
/////////////////////////////////////////////
Widget journalTile(
    BuildContext context,
    String journalName,
    Function changeActiveJournal,
    Function updateSharingList,
    Function updateJournalSharingInDB,
    Function updateJournalsListName,
    Function deleteJournal) {
  return new ListTile(
    leading: journalName != "Personal"
        ? IconButton(
            icon: Icon(Icons.settings),
            onPressed: () =>
                // {

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return journalSettings(
                        context,
                        journalName,
                        updateSharingList,
                        updateJournalSharingInDB,
                        updateJournalsListName,
                        deleteJournal);
                  },
                  barrierDismissible: false,
                ))
        : null,
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
    title: Text('Create a new journal'),
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
          hintText: "Journal name",
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

/////////////////////////////////////////////
/// OPEN JOURNAL SETTING
/////////////////////////////////////////////
Widget journalSettings(
    BuildContext context,
    String title,
    Function updateSharingList,
    Function updateJournalSharingInDB,
    Function updateJournalsListName,
    Function deleteJournal) {
  return AlertDialog(
    title: Text("$title: Settings"),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              Text("Manage your sharing settings"),
              inkling.userProfile["friends"].length > 0
                  ? Container(
                      height: MediaQuery.of(context).size.height / 3,
                      width: double.maxFinite,
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: inkling.userProfile["friends"].length,
                          itemBuilder: (BuildContext context, int index) {
                            return addFriendJournalSharing(
                              context,
                              title,
                              inkling.userProfile["friends"][index],
                              updateSharingList,
                            );
                          }),
                    )
                  : SizedBox(
                      height: 0,
                    )
            ] +
            [
              SizedBox(
                height: 10,
              ),
              RaisedButton(
                onPressed: () {
                  updateJournalSharingInDB(title);
                  Navigator.of(context).pop();
                },
                color: Colors.purpleAccent,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Update settings',
                    style: TextStyle(fontSize: 25, color: Colors.white),
                  ),
                ),
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)),
              ),
              SizedBox(
                height: 10,
              ),
              RaisedButton(
                onPressed: () {
                  showDialog<void>(
                      context: context,
                      barrierDismissible: false, // user must tap button!
                      builder: (BuildContext context) {
                        return changeDiaryName(
                            context, title, updateJournalsListName);
                      });
                },
                color: Colors.purpleAccent,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Change name',
                    style: TextStyle(fontSize: 25, color: Colors.white),
                  ),
                ),
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)),
              ),
            ],
      ),
    ),
    actions: <Widget>[
      FlatButton(
          child: Text('Delete journal'),
          onPressed: () {
            showDialog<void>(
                context: context,
                barrierDismissible: false, // user must tap button!
                builder: (BuildContext context) {
                  return deleteDiary(context, title, deleteJournal);
                });
          }),
      // FlatButton(
      //     child: Text('Change Journal Name'),
      //     onPressed: () {
      //       Navigator.of(context).pop();
      //     }),
      FlatButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          })
    ],
  );
}

/////////////////////////////////////////////
/// ADD FRIENDS TO JOURNAL
/////////////////////////////////////////////
Widget addFriendJournalSharing(BuildContext context, String title,
    Map<String, dynamic> friend, Function updateSharingList) {
  return new StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
    List<dynamic> sharingWith = inkling.currentlySharingWith.containsKey(title)
        ? inkling.currentlySharingWith[title]
        : [];
    return CheckboxListTile(
      value: sharingWith.contains(friend["email"]),
      onChanged: (value) => {
        if (value == true)
          {
            setState(() => {
                  sharingWith.add(friend["email"]),
                  updateSharingList(title, sharingWith),
                })
          }
        else
          {
            setState(() => {
                  sharingWith.remove(friend["email"]),
                  updateSharingList(title, sharingWith),
                })
          }
      },
      title: Text(friend["name"].toString()),
      subtitle: Text(friend["email"]),
    );
  });
}

/////////////////////////////////////////////
/// DELETE JOURNAL ALERT
/////////////////////////////////////////////
Widget deleteDiary(BuildContext context, String title, Function deleteJournal) {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _deleteController = TextEditingController();

  return AlertDialog(
    title: Text('Are you sure you want to delete $title?'),
    content: Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        autofocus: true,
        controller: _deleteController,
        onSaved: (String value) {
          _deleteController.clear();
        },
        decoration: InputDecoration(
          hintText: "Type DELETE to confirm",
          suffixIcon: IconButton(
            onPressed: () => _deleteController.clear(),
            icon: Icon(Icons.clear),
          ),
        ),
        validator: (value) {
          if (value.isEmpty) {
            return 'Please enter DELETE';
          } else if (value != "DELETE") {
            return "Please enter DELETE";
          }
          return null;
        },
      ),
    ),
    actions: <Widget>[
      FlatButton(
          child: Text('Confirm'),
          onPressed: () {
            if (_formKey.currentState.validate()) {
              //   updateJournal(_diaryController.text);
              deleteJournal(title);
              _formKey.currentState.save();
              Navigator.of(context).pop();
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

/////////////////////////////////////////////
/// CHANGE DIARY NAME
/////////////////////////////////////////////
Widget changeDiaryName(
    BuildContext context, String title, Function updateJournalsListName) {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _nameChangeController = TextEditingController();

  return AlertDialog(
    title: Text('Enter a new name for $title'),
    content: Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        autofocus: true,
        controller: _nameChangeController,
        onSaved: (String value) {
          _nameChangeController.clear();
        },
        decoration: InputDecoration(
          hintText: "Enter a valid name",
          suffixIcon: IconButton(
            onPressed: () => _nameChangeController.clear(),
            icon: Icon(Icons.clear),
          ),
        ),
        validator: (value) {
          if (value.isEmpty) {
            return 'Please enter a name';
          } else if (inkling.userProfile['journals_list'].contains(value) ==
              true) {
            return "A journal with that name already exists.";
          }
          return null;
        },
      ),
    ),
    actions: <Widget>[
      FlatButton(
          child: Text('Confirm'),
          onPressed: () {
            List<dynamic> journalsList = inkling.userProfile["journals_list"];
            int titleIndex = journalsList.indexOf(title);
            journalsList[titleIndex] = _nameChangeController.text;
            updateJournalsListName(
                journalsList, title, _nameChangeController.text);
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            FocusScope.of(context).unfocus();
          }),
      FlatButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
            FocusScope.of(context).unfocus();
          })
    ],
  );
}
