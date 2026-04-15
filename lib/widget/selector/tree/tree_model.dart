part of 'tree_selector.dart';

abstract class BaseTreeData<T>{
  Future<List<T>> getTreeData();
  String getName();
}