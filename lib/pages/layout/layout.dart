import 'package:flutter/material.dart';
import 'package:flutter_admin/components/cryRoot.dart';
import 'package:flutter_admin/models/configuration.dart';
import 'package:flutter_admin/models/menu.dart';
import 'package:flutter_admin/pages/common/page401.dart';
import 'package:flutter_admin/pages/layout/layoutAppBar.dart';
import 'package:flutter_admin/pages/layout/layoutMenu.dart';
import 'package:flutter_admin/pages/layout/layoutSetting.dart';
import 'package:flutter_admin/utils/storeUtil.dart';
import 'package:flutter_admin/vo/treeVO.dart';
import 'package:intl/intl.dart';

class Layout extends StatefulWidget {
  final String path;
  final Widget content;
  Layout({this.content, this.path});
  @override
  _LayoutState createState() => _LayoutState();
}

class _LayoutState extends State<Layout> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldStateKey = GlobalKey<ScaffoldState>();
  TabController tabController;
  Widget content;

  @override
  void initState() {
    super.initState();
    content = widget.content;
    handleRoute();
  }

  handleRoute() {
    String path = widget.path;
    int index = StoreUtil.treeVOOpened.indexWhere((v) => v.data.url == path);
    if (index > -1) {
    } else if (StoreUtil.treeVOList == null) {
      StoreUtil.loadMenuData().then((res) {
        setState(() {
          handleRoute();
        });
      });
    } else if (path == '/') {
      StoreUtil.treeVOOpened = [];
      if (StoreUtil.treeVOList.length == 0) {
        this.content = Page401();
      }
    } else {
      TreeVO<Menu> treeVO = StoreUtil.treeVOList.firstWhere((v) {
        return v.data.url == path;
      }, orElse: () => null);
      if (treeVO == null) {
        StoreUtil.treeVOOpened = [];
        this.content = Page401();
      } else {
        StoreUtil.treeVOOpened.add(treeVO);
      }
    }
    int length = StoreUtil.treeVOOpened.length;
    tabController = TabController(vsync: this, length: length);
    tabController.index = index > -1 ? index : (length > 0 ? length - 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    if (StoreUtil.treeVOOpened.length != tabController.length) {
      return Container();
    }
    Color themeColor = CryRootScope.of(context).state.configuration.themeColor;
    TabBar tabBar = TabBar(
      onTap: (index) => _openPage(StoreUtil.treeVOOpened[index]),
      controller: tabController,
      isScrollable: true,
      indicator: const UnderlineTabIndicator(),
      tabs: StoreUtil.treeVOOpened.map<Tab>((TreeVO<Menu> treeVO) {
        return Tab(
          child: Row(
            children: <Widget>[
              Text(Configuration.of(context).locale == 'en' ? treeVO.data.nameEn ?? '' : treeVO.data.name ?? ''),
              SizedBox(width: 3),
              InkWell(
                child: Icon(Icons.close, size: 10),
                onTap: () {
                  _closePage(treeVO);
                },
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
              Container(
                child: Expanded(
                  child: content ?? Container(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    Scaffold subWidget = Scaffold(
      key: scaffoldStateKey,
      endDrawer: LayoutSetting(),
      appBar: LayoutAppBar(context, type: 1, openSetting: () {
        scaffoldStateKey.currentState.openEndDrawer();
      }),
      body: body,
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

  _openPage(TreeVO<Menu> treeVO) {
    int index = StoreUtil.treeVOOpened.indexWhere((note) => note.data.id == treeVO.data.id);
    if (index == -1) {
      StoreUtil.treeVOOpened.add(treeVO);
    }
    Navigator.popAndPushNamed(context, treeVO.data.url);
  }

  _closePage(TreeVO<Menu> treeVO) {
    int index = StoreUtil.treeVOOpened.indexWhere((note) => note.data.id == treeVO.data.id);
    StoreUtil.treeVOOpened.remove(treeVO);
    if (StoreUtil.treeVOOpened.length == 0) {
      Navigator.popAndPushNamed(context, '/');
      return;
    }
    if (index == tabController.index) {
      TreeVO<Menu> openPage = StoreUtil.treeVOOpened[0];
      _openPage(openPage);
      return;
    }
    tabController = TabController(vsync: this, length: StoreUtil.treeVOOpened.length);
    setState(() {});
  }
}
