import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_admin/components/cryRoot.dart';
import 'package:flutter_admin/models/configuration.dart';
import 'package:flutter_admin/pages/layout/layoutAppBar.dart';
import 'package:flutter_admin/routes/routes.dart';
import 'package:flutter_admin/models/menu.dart';
import 'package:flutter_admin/pages/layout/layoutMenu.dart';
import 'package:flutter_admin/pages/layout/layoutSetting.dart';
import 'package:flutter_admin/utils/storeUtil.dart';
import 'package:flutter_admin/vo/treeVO.dart';
import 'package:intl/intl.dart';

class Layout extends StatefulWidget {
  @override
  _LayoutState createState() => _LayoutState();
}

class _LayoutState extends State with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldStateKey = GlobalKey<ScaffoldState>();
  List<TreeVO<Menu>> treeVOOpened = [];
  TabController tabController;
  Container content = Container();
  int length = 0;

  @override
  void initState() {
    super.initState();

    tabController = TabController(vsync: this, length: length);
  }

  @override
  Widget build(BuildContext context) {
    if (StoreUtil.treeVOList == null) {
      StoreUtil.loadMenuData().then((res) {
        setState(() {});
      });
      return Container();
    }

    Color themeColor = CryRootScope.of(context).state.configuration.themeColor;
    TabBar tabBar = TabBar(
      onTap: (index) => _openPage(treeVOOpened[index]),
      controller: tabController,
      isScrollable: true,
      indicator: const UnderlineTabIndicator(),
      tabs: treeVOOpened.map<Tab>((TreeVO<Menu> treeVO) {
        return Tab(
          child: Row(
            children: <Widget>[
              Text(Configuration.of(context).locale == 'en' ? treeVO.data.nameEn ?? '' : treeVO.data.name ?? ''),
              SizedBox(width: 3),
              InkWell(
                child: Icon(Icons.close, size: 10),
                onTap: () => _closePage(treeVO),
              ),
            ],
          ),
        );
      }).toList(),
    );

    Row body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutMenu(onClick: _openPage),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      child: tabBar,
                      decoration: BoxDecoration(
                        color: themeColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            offset: Offset(2.0, 2.0),
                            blurRadius: 4.0,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              content,
            ],
          ),
        ),
      ],
    );
    Scaffold subWidget = Scaffold(
      key: scaffoldStateKey,
      endDrawer: LayoutSetting(),
      body: body,
      appBar: LayoutAppBar(context, type: 2, openSetting: () {
        scaffoldStateKey.currentState.openEndDrawer();
      }),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.settings),
      //   onPressed: () {
      //     scaffoldStateKey.currentState.openEndDrawer();
      //   },
      // ),
    );
    return Theme(
      data: ThemeData(
        primaryColor: themeColor,
        iconTheme: IconThemeData(color: themeColor),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: themeColor,
        ),
        buttonTheme: ButtonThemeData(buttonColor: themeColor),
      ),
      child: subWidget,
    );
  }

  _closePage(treeVO) {
    treeVOOpened.remove(treeVO);
    --length;
    tabController = TabController(vsync: this, length: length);
    var openPage;
    if (length > 0) {
      tabController.index = length - 1;
      openPage = treeVOOpened[0];
    }
    _openPage(openPage);
    setState(() {});
  }

  _openPage(TreeVO<Menu> treeVO) {
    if (treeVO == null) {
      content = Container();
      return;
    }
    Widget body = treeVO.data.url != null && layoutRoutesData[treeVO.data.url] != null
        ? layoutRoutesData[treeVO.data.url]
        : Center(child: Text('404'));
    content = Container(
      child: Expanded(
        child: body,
      ),
    );

    int index = treeVOOpened.indexWhere((note) => note.data.id == treeVO.data.id);
    if (index > -1) {
      tabController.index = index;
    } else {
      treeVOOpened.add(treeVO);
      tabController = TabController(vsync: this, length: ++length);
      tabController.index = length - 1;
    }
    setState(() {});
  }
}
