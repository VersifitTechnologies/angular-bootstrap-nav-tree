
module = angular.module 'angularBootstrapNavTree',[]

module.directive 'abnTree', ['$timeout', ($timeout) ->
  restrict: 'E'

  template: """
<ul class="nav nav-list nav-pills nav-stacked abn-tree">
  <li ng-repeat="row in tree_rows | filter:{visible:true} track by row.branch.uid" ng-animate="'abn-tree-animate'" ng-class="'level-' + {{ row.level }} + (row.branch.selected ? ' active':'')" class="abn-tree-row"><a ng-click="user_clicks_branch(row.branch)"><i ng-class="row.tree_icon" ng-click="row.branch.expanded = !row.branch.expanded" class="indented tree-icon"> </i><span class="indented tree-label">{{ row.label }} </span></a></li>
</ul>""" # will be replaced by Grunt, during build, with the actual Template HTML
  replace: true
  scope:
    treeData: '='
    onSelect: '&'
    initialSelection: '@'
    treeControl: '='

  link: (scope, element, attrs) ->

    currentUID = 0

    error = (s) ->
      console.error "ERROR: #{s}"

    # default values ( Font-Awesome 3 or 4 or Glyphicons )
    attrs.iconExpand   ?= 'icon-plus  glyphicon glyphicon-plus  fa fa-plus'    
    attrs.iconCollapse ?= 'icon-minus glyphicon glyphicon-minus fa fa-minus'
    attrs.iconLeaf     ?= 'icon-file  glyphicon glyphicon-file  fa fa-file'

    attrs.expandLevel  ?= '3'

    expand_level = parseInt attrs.expandLevel, 10

    # check args
    return error 'no treeData defined for the tree!' if not scope.treeData
    return error 'treeData should be an array of root branches' if not scope.treeData

    #
    # internal utilities...
    # 
    for_each_branch = (f) ->

      do_f = (branch, level) ->
        f branch, level
        do_f child, level + 1 for child in branch.children if branch.children

      do_f root_branch, 1 for root_branch in scope.treeData


    #
    # only one branch can be selected at a time
    # 
    selected_branch = null
    select_branch = (branch) ->

      if not branch
        selected_branch?.selected = no
        selected_branch = null
        return

      if branch isnt selected_branch
        selected_branch?.selected = no

        branch.selected = yes
        selected_branch = branch
        expand_all_parents branch

        #
        # check:
        # 1) branch.onSelect
        # 2) tree.onSelect
        #
        if branch.onSelect? then $timeout -> branch.onSelect branch

        else if scope.onSelect? then $timeout -> scope.onSelect branch: branch

        #
        # use $timeout
        # so that the branch becomes fully selected
        # ( and highlighted )
        # before calling the "onSelect" function.
        #

      branch

    scope.user_clicks_branch = (branch) ->
      select_branch branch if branch isnt selected_branch

    get_parent = (child) ->
      parent = null
      (for_each_branch (b) -> parent = b if b.uid is child.parent_uid) if child.parent_uid

      parent

    for_all_ancestors = (child, fn) ->
      return if not parent = get_parent child
      fn parent
      for_all_ancestors parent, fn

    expand_all_parents = (child) ->
      for_all_ancestors child, (b) -> b.expanded = yes

    #
    # To make the Angular rendering simpler,
    #  ( and to avoid recursive templates )
    #  we transform the TREE of data into a LIST of data.
    #  ( "tree_rows" )
    #
    # We do this whenever data in the tree changes.
    # The tree itself is bound to this list.
    # 
    # Children of un-expanded parents are included, 
    #  but are set to "visible:false" 
    #  ( and then they filtered out during rendering )
    #
    scope.tree_rows = []
    on_treeData_change = ->

      scope.tree_rows = []

      #console.log 'tree-data-change!'

      # give each Branch a UID ( to keep AngularJS happy )
      for_each_branch (b) -> b.uid = ++currentUID if not b.uid

      # set all parents:
      for_each_branch (b) -> child.parent_uid = b.uid for child in b.children if angular.isArray b.children

      #
      # if "children" is just a list of strings...
      # ...change them into objects:
      # 
      for_each_branch (branch) ->

        branch.children = [] if not branch.children

        return if branch.children.length is 0

        # don't use Array.map ( old browsers don't have it )
        f = (e) ->
          return e if not angular.isString e

          label: e
          children: []

        branch.children = ( f child for child in branch.children )

      #
      # add_branch_to_list: recursively add one branch
      # and all of it's children to the list
      #
      add_branch_to_list = (level, branch, visible) ->

        branch.expanded = no if not branch.expanded

        #
        # icons can be Bootstrap or Font-Awesome icons:
        # they will be rendered like:
        # <i class="icon-plus"></i>
        #
        if not branch.children or branch.children.length is 0
          tree_icon = attrs.iconLeaf
        else
          tree_icon = if branch.expanded then attrs.iconCollapse else attrs.iconExpand

        #
        # append to the list of "Tree Row" objects:
        #
        scope.tree_rows.push
          level     : level
          branch    : branch
          label     : branch.label
          tree_icon : tree_icon
          visible   : visible

        #
        # recursively add all children of this branch...( at Level+1 )
        #
        return if not branch.children

        #
        # all branches are added to the list,
        #  but some are not visible
        # ( if parent is collapsed )
        #
        add_branch_to_list level+1, child, (visible and branch.expanded) for child in branch.children

      #
      # start with root branches,
      # and recursively add all children to the list
      #
      add_branch_to_list 1, root_branch, yes for root_branch in scope.treeData

    #
    # make sure to do a "deep watch" on the tree data
    # ( by passing "true" as the third arg )
    #
    scope.$watch 'treeData', on_treeData_change, yes

    #
    # initial-selection="Branch Label"
    # if specified, find and select the branch:
    #
    (for_each_branch (b) -> ($timeout -> select_branch b if b.label is attrs.initialSelection)) if attrs.initialSelection

    #
    # expand to the proper level
    #
    n = scope.treeData.length

    for_each_branch (b, level) ->
      b.level = level
      b.expanded = b.level < expand_level

    #
    # TREE-CONTROL : the API to the Tree
    #
    #  if we have been given an Object for this,
    #  then we attach all of tree-control functions 
    #  to that given object:
    #
    return if not angular.isObject scope.treeControl

    tree = scope.treeControl

    tree.expand_all = ->
      for_each_branch (b)-> b.expanded = yes

    tree.collapse_all = ->
      for_each_branch (b)-> b.expanded = no

    tree.get_first_branch = ->
      scope.treeData[0] if scope.treeData.length > 0

    tree.select_first_branch = ->
      tree.select_branch tree.get_first_branch()

    tree.get_selected_branch = ->
      selected_branch

    tree.get_parent_branch = (b) ->
      get_parent b

    tree.select_branch = (b) ->
      select_branch b

    tree.get_children = (b) ->
      b.children

    tree.select_parent_branch = (b) ->
      return if not b ?= tree.get_selected_branch()

      p = tree.get_parent_branch b
      tree.select_branch p if p

    tree.add_branch = (parent, new_branch) ->
      if parent
        parent.children.push new_branch
        parent.expanded = yes
      else
        scope.treeData.push new_branch

      new_branch

    tree.add_root_branch = (new_branch) ->
      tree.add_branch null, new_branch

    tree.expand_branch = (b) ->
      return if not b ?= tree.get_selected_branch()

      b.expanded = yes
      b

    tree.collapse_branch = (b) ->
      return if not b ?= tree.get_selected_branch()

      b.expanded = no
      b

    tree.get_siblings = (b) ->
      return [] if not b ?= tree.get_selected_branch()

      p = tree.get_parent_branch b
      # either the parents children or the root
      if p then p.children else scope.treeData

    tree.get_next_sibling = (b) ->
      return if not b ?= tree.get_selected_branch()

      siblings = tree.get_siblings b
      i = siblings.indexOf b
      siblings[i+1] if i < siblings.length

    tree.get_prev_sibling = (b) ->
      return if not b ?= tree.get_selected_branch()

      siblings = tree.get_siblings b
      i = siblings.indexOf b
      siblings[i-1] if i > 0

    tree.select_next_sibling = (b) ->
      return if not b ?= tree.get_selected_branch()

      next = tree.get_next_sibling b
      tree.select_branch next if next

    tree.select_prev_sibling = (b) ->
      return if not b ?= tree.get_selected_branch()

      prev = tree.get_prev_sibling b
      tree.select_branch prev if prev

    tree.get_first_child = (b) ->
      return if not b ?= tree.get_selected_branch()

      b.children?[0]

    tree.get_closest_ancestor_next_sibling = (b) ->
      next = tree.get_next_sibling b
      return next if next

      tree.get_closest_ancestor_next_sibling tree.get_parent_branch b

    #
    # "next" in the sense of...vertically, from top to bottom
    #
    # try:
    # 1) next sibling
    # 2) first child
    # 3) parent.get_next() // recursive
    #
    tree.get_next_branch = (b) ->
      return if not b ?= tree.get_selected_branch()

      next = tree.get_first_child b
      if next then next else tree.get_closest_ancestor_next_sibling b

    tree.select_next_branch = (b)->
      return if not b ?= tree.get_selected_branch()

      next = tree.get_next_branch(b)
      if next?
        tree.select_branch(next)
        next


    tree.last_descendant = (b)->
      n = b.children.length
      if n is 0 then b else tree.last_descendant b.children[n-1]

    tree.get_prev_branch = (b)->
      return if not b ?= tree.get_selected_branch()

      prev_sibling = tree.get_prev_sibling(b)
      if prev_sibling then tree.last_descendant prev_sibling else tree.get_parent_branch b

    tree.select_prev_branch = (b)->
      return if not b ?= tree.get_selected_branch()
      prev = tree.get_prev_branch(b)
      tree.select_branch prev if prev
]










