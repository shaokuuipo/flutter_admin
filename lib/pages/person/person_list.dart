import 'package:bot_toast/bot_toast.dart';
import 'package:cry/form1/cry_input.dart';
import 'package:cry/form1/cry_select.dart';
import 'package:cry/model/order_item_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin/api/person_api.dart';
import 'package:cry/cry_button.dart';
import 'package:cry/cry_dialog.dart';
import 'package:flutter_admin/constants/constant_dict.dart';
import 'package:cry/model/page_model.dart';
import 'package:flutter_admin/models/person.dart';
import 'package:cry/model/request_body_api.dart';
import 'package:cry/model/response_body_api.dart';
import 'package:flutter_admin/utils/dict_util.dart';
import '../../generated/l10n.dart';
import 'person_dit.dart';

class PersonList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PersonListState();
  }
}

class PersonListState extends State {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  int rowsPerPage = 10;
  MyDS myDS = new MyDS();
  Person formData = Person();

  _reset() {
    this.formData = Person();
    formKey.currentState.reset();
    myDS.requestBodyApi.params = formData.toJson();
    myDS.loadData();
  }

  _query() {
    formKey.currentState.save();
    myDS.requestBodyApi.params = formData.toJson();
    myDS.loadData();
  }

  _edit({Person person}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: PersonEdit(
          person: person,
        ),
      ),
    ).then((v) {
      if (v != null) {
        _query();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    myDS.context = context;
    myDS.state = this;
    myDS.page.size = rowsPerPage;
    myDS.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((c) {
      _query();
    });
  }

  @override
  Widget build(BuildContext context) {
    var form = Form(
      key: formKey,
      child: Wrap(
        children: <Widget>[
          CryInput(
            label: S.of(context).personName,
            value: formData.name,
            onSaved: (v) {
              formData.name = v;
            },
          ),
          CrySelect(
            label: S.of(context).personDepartment,
            value: formData.deptId,
            dataList: DictUtil.getDictSelectOptionList(ConstantDict.CODE_DEPT),
            onSaved: (v) {
              formData.deptId = v;
            },
          ),
        ],
      ),
    );

    ButtonBar buttonBar = ButtonBar(
      alignment: MainAxisAlignment.start,
      children: <Widget>[
        CryButton(label: S.of(context).inquire,iconData: Icons.search, onPressed: () => _query()),
        CryButton(label: S.of(context).reset,iconData: Icons.refresh, onPressed: () => _reset()),
        CryButton(label: S.of(context).increase,iconData: Icons.add, onPressed: () => _edit()),
        CryButton(
          label: S.of(context).modify,
          iconData: Icons.edit,
          onPressed: myDS.selectedCount != 1
              ? null
              : () {
                  if (myDS.selectedRowCount != 1) {
                    return;
                  }
                  Person person = myDS.dataList.firstWhere((v) {
                    return v.selected;
                  });
                  _edit(person: person);
                },
        ),
        CryButton(
          label: S.of(context).delete,
          iconData: Icons.delete,
          onPressed: myDS.selectedCount < 1
              ? null
              : () {
                  cryConfirm(context, S.of(context).confirmDelete, () async {
                    List ids = myDS.dataList.where((v) {
                      return v.selected;
                    }).map<String>((v) {
                      return v.id;
                    }).toList();
                    await PersonApi.removeByIds(ids);
                    _query();
                    Navigator.of(context).pop();
                  });
                },
        ),
      ],
    );

    Scrollbar table = Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(10.0),
        children: <Widget>[
          PaginatedDataTable(
            header: Text(S.of(context).userList),
            rowsPerPage: rowsPerPage,
            onRowsPerPageChanged: (int value) {
              setState(() {
                rowsPerPage = value;
                myDS.page.size = rowsPerPage;
                myDS.loadData();
              });
            },
            availableRowsPerPage: <int>[2, 5, 10, 20],
            onPageChanged: myDS.onPageChanged,
            columns: <DataColumn>[
              DataColumn(
                label: Text(S.of(context).name),
                onSort: (int columnIndex, bool ascending) => myDS.sort('name', ascending),
              ),
              DataColumn(
                label: Text(S.of(context).personNickname),
                onSort: (int columnIndex, bool ascending) => myDS.sort('nick_name', ascending),
              ),
              DataColumn(
                label: Text(S.of(context).personGender),
                onSort: (int columnIndex, bool ascending) => myDS.sort('gender', ascending),
              ),
              DataColumn(
                label: Text(S.of(context).personBirthday),
                onSort: (int columnIndex, bool ascending) => myDS.sort('birthday', ascending),
              ),
              DataColumn(
                label: Text(S.of(context).personDepartment),
                onSort: (int columnIndex, bool ascending) => myDS.sort('dept_id', ascending),
              ),
              DataColumn(
                label: Text(S.of(context).creationTime),
                onSort: (int columnIndex, bool ascending) => myDS.sort('create_time', ascending),
              ),
              DataColumn(
                label: Text(S.of(context).updateTime),
                onSort: (int columnIndex, bool ascending) => myDS.sort('update_time', ascending),
              ),
              DataColumn(
                label: Text(S.of(context).operating),
              ),
            ],
            source: myDS,
          ),
        ],
      ),
    );
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 10),
          form,
          buttonBar,
          Expanded(
            child: table,
          ),
        ],
      ),
    );
  }
}

class MyDS extends DataTableSource {
  MyDS();

  PersonListState state;
  BuildContext context;
  List<Person> dataList;
  int selectedCount = 0;
  RequestBodyApi requestBodyApi = RequestBodyApi();
  PageModel page = PageModel(orders: [OrderItemModel(column: 'create_time', asc: false)]);

  sort(column, ascending) {
    page.orders[0].column = column;
    page.orders[0].asc = !page.orders[0].asc;
    loadData();
  }

  loadData() async {
    BotToast.showLoading();
    requestBodyApi.page = page;
    ResponseBodyApi responseBodyApi = await PersonApi.page(requestBodyApi.toMap());
    page = PageModel.fromMap(responseBodyApi.data);
    BotToast.closeAllLoading();

    dataList = page.records.map<Person>((v) {
      Person person = Person.fromJson(v);
      person.selected = false;
      return person;
    }).toList();
    selectedCount = 0;
    notifyListeners();
  }

  onPageChanged(firstRowIndex) {
    page.current = firstRowIndex / page.size + 1;
    loadData();
  }

  @override
  DataRow getRow(int index) {
    var dataIndex = index - page.size * (page.current - 1);

    if (dataIndex >= dataList.length) {
      return null;
    }
    Person person = dataList[dataIndex];

    return DataRow.byIndex(
      index: index,
      selected: person.selected,
      onSelectChanged: (bool value) {
        person.selected = value;
        selectedCount += value ? 1 : -1;
        notifyListeners();
      },
      cells: <DataCell>[
        DataCell(Text(person.name ?? '--')),
        DataCell(Text(person.nickName ?? '--')),
        DataCell(Text(DictUtil.getDictItemName(
          person.gender,
          ConstantDict.CODE_GENDER,
        ))),
        DataCell(Text(person.birthday ?? '--')),
        DataCell(Text(DictUtil.getDictItemName(
          person.deptId,
          ConstantDict.CODE_DEPT,
          defaultValue: '--',
        ))),
        DataCell(Text(person.createTime ?? '--')),
        DataCell(Text(person.updateTime ?? '--')),
        DataCell(ButtonBar(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                state._edit(person: person);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                cryConfirm(context, S.of(context).confirmDelete, () async {
                  await PersonApi.removeByIds([person.id]);
                  loadData();
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => page.total;

  @override
  int get selectedRowCount => selectedCount;
}
