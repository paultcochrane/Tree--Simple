use v6;
use Test;
plan 34;
BEGIN
{
    @*INC.push('lib');
    @*INC.push('blib');
}



eval_lives_ok 'use Tree::Simple', 'Can use Tree::Simple';

use Tree::Simple;
#since do not have Test::Memory::Cycle module, so just testing the destroy function
# eval "use Test::Memory::Cycle 1.02";
# plan skip_all => "Test::Memory::Cycle required for testing memory leaks" if $@;
#diag "parental connections must be destroyed manually";

#{ #diag "verify the problem exists";
{
    
    my $tree2 = Tree::Simple.new("2");
    ok($tree2.isRoot(), '... tree2 is a ROOT');    
    my $tree1_UID;
    {
        my $tree1 = Tree::Simple.new("1");
        $tree1_UID = $tree1.getUID();
        $tree1.addChild($tree2);
        ok(!$tree2.isRoot(), '... now tree2 is not a ROOT');

        #         memory_cycle_exists($tree2, '... there is a cycle in tree2');
    }
    
    #     memory_cycle_exists($tree2, '... tree1 is still connected with tree2');
    ok(!$tree2.isRoot(), '... now tree2 is not a ROOT');
    ok(defined($tree2.getParent()), '... now tree2s parent is still defined');    
    is($tree2.getParent().getUID(), $tree1_UID, '... and tree2s parent is tree1');        

}

# { #diag "this fixes the problem";
{
    
    my $tree2 = Tree::Simple.new("2");
    ok($tree2.isRoot(), '... tree2 is a ROOT');    
    
    {
        my $tree1 = Tree::Simple.new("1");
        $tree1.addChild($tree2);
        ok(!$tree2.isRoot(), '... now tree2 is not a ROOT');

        #         memory_cycle_exists($tree2, '... there is a cycle in tree2');
        $tree1.DESTROY();
    }
    
    #     memory_cycle_ok($tree2, '... calling DESTORY on tree1 broke the connection with tree2');
    ok($tree2.isRoot(), '... now tree2 is a ROOT again');
    ok(!defined($tree2.getParent()), '... now tree2s parent is no longer defined');    
 }

#diag "expand the original problem and see how it effects children";

{ 

    my $tree2 = Tree::Simple.new("2");
    ok($tree2.isRoot(), '... tree2 is a ROOT');  
    ok($tree2.isLeaf(), '... tree2 is a Leaf');      
    my $tree3 = Tree::Simple.new("3");  
    ok($tree3.isRoot(), '... tree3 is a ROOT');  
    ok($tree3.isLeaf(), '... tree3 is a Leaf'); 
    
    {
        my $tree1 = Tree::Simple.new("1");
        $tree1.addChild($tree2);
        ok(!$tree2.isRoot(), '... now tree2 is not a ROOT');
        $tree2.addChild($tree3);
        ok(!$tree2.isLeaf(), '... now tree2 is not a Leaf');
        ok(!$tree3.isRoot(), '... tree3 is no longer a ROOT');  
        ok($tree3.isLeaf(), '... but tree3 is still a Leaf'); 
        
        #         memory_cycle_exists($tree1, '... there is a cycle in tree1');
        #         memory_cycle_exists($tree2, '... there is a cycle in tree2');
        #         memory_cycle_exists($tree3, '... there is a cycle in tree3');        
        $tree1.DESTROY();
        
        #         memory_cycle_exists($tree1, '... there is still a cycle in tree1 because of the children');
    }
    
    #     memory_cycle_exists($tree2, '... calling DESTORY on tree1 broke the connection with tree2');
    ok($tree2.isRoot(), '... now tree2 is a ROOT again');
    ok(!$tree2.isLeaf(), '... now tree2 is not a leaf again');    
    ok(!defined($tree2.getParent()), '... now tree2s parent is no longer defined');    
    is($tree2.getChildCount(), 1, '... now tree2 has one child');    
    #     memory_cycle_exists($tree3, '... calling DESTORY on tree1 did not break the connection betwee tree2 and tree3');
    ok(!$tree3.isRoot(), '... now tree3 is not a ROOT');
    ok($tree3.isLeaf(), '... now tree3 is still a leaf');    
    ok(defined($tree3.getParent()), '... now tree3s parent is still defined'); 
    is($tree3.getParent(), $tree2, '... now tree3s parent is still tree2');           
}

#diag "child connections are strong";
{
    my $tree1 = Tree::Simple.new("1");
    my $tree2_UID;
    
    {
        my $tree2 = Tree::Simple.new("2");    
        $tree1.addChild($tree2);
        $tree2_UID = $tree2.getUID();
        
        #         memory_cycle_exists($tree1, '... tree1 is connected to tree2');
        #         memory_cycle_exists($tree2, '... tree2 is connected to tree1');    
        
        $tree2.DESTROY(); # this doesn't make sense to do
    }

    #     memory_cycle_exists($tree1, '... tree2 is still connected to tree1 because child connections are strong');
    is($tree1.getChild(0).getUID(), $tree2_UID, '... tree2 is still connected to tree1');
    is($tree1.getChild(0).getParent(), $tree1, '... tree2s parent is tree1');
    is($tree1.getChildCount(), 1, '... tree1 has a child count of 1');        
}

#diag "expand upon this issue";
{
    my $tree1 = Tree::Simple.new("1");
    my $tree2_UID;
    my $tree3 = Tree::Simple.new("3");    

    {
        my $tree2 = Tree::Simple.new("2");    
        $tree1.addChild($tree2);
        $tree2_UID = $tree2.getUID();
        $tree2.addChild($tree3);
        
        #         memory_cycle_exists($tree1, '... tree1 is connected to tree2');
        #         memory_cycle_exists($tree2, '... tree2 is connected to tree1');    
        #         memory_cycle_exists($tree3, '... tree3 is connected to tree2');            
        
        $tree2.DESTROY(); # this doesn't make sense to do
    }

    #     memory_cycle_exists($tree1, '... tree2 is still connected to tree1 because child connections are strong');
    is($tree1.getChild(0).getUID(), $tree2_UID, '... tree2 is still connected to tree1');
    is($tree1.getChild(0).getParent(), $tree1, '... tree2s parent is tree1');
    is($tree1.getChildCount(), 1, '... tree1 has a child count of 1');        
    is($tree1.getChild(0).getChildCount(), 1, '... tree2 is still connected to tree3');
    is($tree1.getChild(0).getChild(0), $tree3, '... tree2 is still connected to tree3');    
}
