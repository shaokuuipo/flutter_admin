import 'package:flutter/material.dart';
import 'package:flutter_admin/models/index.dart' as model;

class CryDataTable extends StatefulWidget {
  CryDataTable({
    Key key,
    this.title = '',
    this.columns,
    this.page,
    this.getCells,
    this.onPageChanged,
    this.onSelectChanged,
  }) : super(key: key);
  final String title;
  final List<DataColumn> columns;
  final Function getCells;
  final Function onPageChanged;
  final Function onSelectChanged;
  final model.Page page;

  @override
  CryDataTableState createState() => CryDataTableState();
}

class CryDataTableState extends State<CryDataTable> {
  _DS _ds = _DS();
  int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _ds._getCells = widget.getCells;
    _ds._onSelectChanged = widget.onSelectChanged;
  }

  @override
  Widget build(BuildContext context) {
    _ds._page = widget.page ?? model.Page();
    _ds.reload();
    var result = ListView(
      padding: const EdgeInsets.all(10.0),
      children: <Widget>[
        PaginatedDataTable(
          header: Text(widget.title),
          rowsPerPage: rowsPerPage,
          onPageChanged: (firstRowIndex) {
            int current = (firstRowIndex / widget.page.size + 1) as int;
            return widget.onPageChanged(current);
          },
          onRowsPerPageChanged: (int value) {
            setState(() {
              rowsPerPage = value;
            });
          },
          columns: widget.columns ?? [DataColumn(label: Text(''))],
          source: _ds,
          showCheckboxColumn: true,
        )
      ],
    );
    return result;
  }

  List<Map> getSelectedList(model.Page page) {
    return (page ?? widget.page)?.records?.where((v) => v['selected'] ?? false)?.toList() ?? [];
  }
}

class _DS extends DataTableSource {
  model.Page _page = model.Page();
  Function _getCells;
  Function _onSelectChanged;

  reload() {
    notifyListeners();
  }

  @override
  DataRow getRow(int index) {
    var dataIndex = index - _page.size * (_page.current - 1);

    if (dataIndex >= _page.records.length) {
      return null;
    }
    Map m = _page.records[dataIndex];

    List<DataCell> cells = _getCells == null ? [] : _getCells(m);
    bool selected = m['selected'] ?? false;
    return DataRow.byIndex(
      index: index,
      cells: cells,
      selected: selected,
      onSelectChanged: (v) {
        m['selected'] = v;
        _onSelectChanged(m);
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _page.total;

  @override
  int get selectedRowCount => (_page?.records?.where((v) => v['selected'] ?? false)?.length) ?? 0;
}