% This file is part of the Stanford GraphBase (c) Stanford University 1992
\def\title{FOOTBALL}
@i boilerplate.w %<< legal stuff: PLEASE READ IT BEFORE MAKING ANY CHANGES!

\prerequisite{GB\_\thinspace GAMES}
@* Introduction. This demonstration program uses graphs
constructed by the |gb_games| module to produce
an interactive program called \.{football}, which finds preposterously
long chains of scores to ``prove'' that one given team might outrank another
by a huge margin.

\def\<#1>{$\langle${\rm#1}$\rangle$}
The program will prompt you for a starting team. If you simply type \<return>,
it exits; otherwise you should enter a team name (e.g., `\.{Stanford}')
before typing \<return>.

Then the program will prompt you for another team. If you simply type
\<return> at this point, it will go back and ask for a new starting team;
otherwise you should specify another name (e.g., `\.{Harvard}').

Then the program will find and display a chain from the starting team
to the other one. For example, you might see
$$\vbox{\halign{\tt#\hfil\cr
 Sep 06: Stanford Cardinal 17, Colorado Buffaloes 21 (-4)\cr
 Nov 17: Colorado Buffaloes 64, Kansas State Wildcats 3 (+57)\cr
 Sep 29: Kansas State Wildcats 38, New Mexico Lobos 6 (+89)\cr
 Sep 22: New Mexico Lobos 32, Texas Tech Red Raiders 34 (+87)\cr
 Nov 17: Texas Tech Red Raiders 62, Southern Methodist Mustangs 7 (+142)\cr
 Sep 08: Southern Methodist Mustangs 44, Vanderbilt Commodores 7 (+179)\cr
\omit\qquad\vdots\cr
 Nov 10: Cornell Big Red 41, Columbia Lions 0 (+2148)\cr
 Sep 15: Columbia Lions 6, Harvard Crimson 9 (+2145)\cr}}$$
This chain isn't necessarily optimal, it's just this
particular program's best guess; algorithms that
find better chains should be fun to invent.

Actually this program has two variants. If you invoke it by saying simply
`\.{football}', you get chains found by a simple ``greedy algorithm.''
But if you invoke it by saying `\.{football} \<number>' (assuming \UNIX\
command-line conventions), the program works harder. Higher values of
\<number> do more calculation and tend to find better chains. For
example, the simple greedy algorithm favors Stanford over Harvard by
only 781; \.{football}~\.{10} raises this to 1939; the
example above corresponds to \.{football}~\.{1000}.

@ We use the data types \&{Area}, \&{Vertex}, \&{Arc}, and \&{Graph}
defined in |gb_graph|.

@f Area int
@f Vertex int
@f Arc int
@f Graph int

@ Here is the general layout of this program, as seen by the \Cee\ compiler:
@^UNIX dependencies@>

@p
#include "gb_graph.h" /* the standard GraphBase data structures */
#include "gb_games.h" /* the routine that sets up the graph of scores */
#include "gb_flip.h" /* random number generator */
@#
@<Type declarations@>@;
@<Global variables@>@;
@<Subroutines@>@;
main(argc,argv)
  int argc; /* the number of command-line arguments */
  char *argv[]; /* an array of strings containing those arguments */
{
  @<Scan the command line options@>;
  @<Set up the graph@>;
  while(1) {
    @<Prompt for starting team and goal team; |break| if none given@>;
    @<Find a chain from |start| to |goal|, and print it@>;
  }
}

@ Let's deal with \UNIX-dependent stuff first. The rest of this program
should work without change on any operating system.
@^UNIX dependencies@>

@<Scan the command line options@>=
if (argc==3 && strcmp(argv[2],"-v")==0) verbose=argc=2; /* secret option */
if (argc==1) width=0;
else if (argc==2 && sscanf(argv[1],"%d",&width)==1) {
  if (width<0) width=-width; /* a \UNIX\ user might have used a hyphen */
} else {
  fprintf(stderr,"Usage: %s [searchwidth]\n",argv[0]);
  return -2;
}

@ @<Glob...@>=
int width; /* number of cases examined per stratum */
Graph *g; /* the graph containing score information */
Vertex *u,*v; /* vertices of current interest */
Arc *a; /* arc of current interest */
Vertex *start,*goal; /* teams specified by the user */
int mm; /* counter used only in |verbose| mode */

@ An arc from |u| to |v| in the graph generated by |games| has a |len| field
equal to the number of points scored by |u| against |v|.
For our purposes we want also a |del| field, which gives the difference
between the number of points scored by |u| and the number of points
scored by~|v| in that game.

@d del a.i /* |del| info appears in utility field |a| of an |Arc| record */

@<Set up the graph@>=
g=games(0,0,0,0,0,0,0,0);
 /* this default graph has the data for the entire 1990 season */
if (g==NULL) {
  fprintf(stderr,"Sorry, can't create the graph! (error code %d)\n",
            panic_code);
  return -1;
}
for (v=g->vertices;v<g->vertices+g->n;v++)
  for (a=v->arcs;a;a=a->next)
    if (a->tip>v) { /* arc |a+1| is the mate of arc |a| iff |a->tip>v| */
      a->del=a->len-(a+1)->len;
      (a+1)->del=-a->del;
    }

@* Terminal interaction. While we're getting trivialities out of the way,
we might as well take care of the simple dialog that transpires
between this program and the user.

@<Prompt for...@>=
putchar('\n'); /* make a blank line for visual punctuation */
restart: /* if we avoid this label, the |break| command will be broken */
if ((start=prompt_for_team("Starting"))==NULL) break;
if ((goal=prompt_for_team("   Other"))==NULL) goto restart;
if (start==goal) {
  printf(" (Um, please give me the names of two DISTINCT teams.)\n");
  goto restart;
}

@ The user must spell team names exactly as they appear in the file
\.{games.dat}. Thus, for example, `\.{Berkeley}' and `\.{Cal}' don't
work; it has to be `\.{California}'. Similarly, a person must type
`\.{Pennsylvania}' instead of `\.{Penn}', `\.{Nevada-Las} \.{Vegas}'
instead of `\.{UNLV}'. A backslash is necessary in `\.{Texas} \.{A\\\&M}'.

@<Sub...@>=
Vertex *prompt_for_team(s)
  char *s; /* string used in prompt message */
{@+register char *q; /* current position in |buffer| */
  register Vertex *v; /* current vertex being examined in sequential search */
  char buffer[30]; /* a line of input */
  while (1) {
    printf("%s team: ",s);
    fflush(stdout); /* make sure the user sees the prompt */
    fgets(buffer,30,stdin);
    if (buffer[0]=='\n') return NULL; /* the user just hit \<return> */
    buffer[29]='\n';
    for (q=buffer;*q!='\n';q++) ; /* scan to end of input */
    *q='\0';
    for (v=g->vertices;v<g->vertices+g->n;v++)
      if (strcmp(buffer,v->name)==0) return v; /* aha, we found it */
    printf(" (Sorry, I don't know any team by that name.)\n");
    printf(" (One team I do know is %s...)\n",
             (g->vertices+gb_unif_rand(g->n))->name);
  }
}

@*Greed. The main task of this program is to find the longest possible
simple path from |start| to |goal|, using |del| as the length of each
arc in the path. This is an NP-complete problem, and the number of
possibilities is pretty huge, so the present program is content to
use heuristics that are reasonably easy to compute. (Researchers are hereby
challenged to come up with better heuristics. Does simulated annealing
give good results? How about genetic algorithms?)

Perhaps the first approach that comes to mind is a simple ``greedy'' approach
in which each step takes the largest possible |del| that doesn't prevent
us from eventually getting to |goal|. So that's the method we will
implement first.

@ @<Find a chain from |start| to |goal|, and print it@>=
@<Initialize the allocation of auxiliary memory@>;
if (width==0) @<Use a simple-minded
  greedy algorithm to find a chain from |start| to |goal|@>@;
else @<Use a stratified heuristic to find a chain from |start| to |goal|@>;
@<Print the solution corresponding to |cur_node|@>;
@<Recycle the auxiliary memory used@>;

@ We might as well use data structures that are more general than we need,
in anticipation of a more complex heuristic that will be implemented later.
The set of all possible solutions can be viewed as a backtrack tree
in which the branches from each node are the games that can possibly
follow that node. We will examine a small part of that gigantic tree.

@<Type declarations@>=
typedef struct node_struct {
  Arc *a; /* game from the current team to the next team */
  int len; /* accumulated length from |start| to here */
  struct node_struct *prev; /* node that gave us the current team */
  struct node_struct *next;
    /* list pointer to node in same stratum (see below) */
} node;

@ @<Glob...@>=
Area node_storage; /* working storage for heuristic calculations */
node *next_node; /* where the next node is slated to go */
node *bad_node; /* end of current allocation block */
node *cur_node; /* current node of particular interest */

@ @<Initialize the allocation of auxiliary memory@>=
next_node=bad_node=NULL;

@ @<Subroutines@>=
node *new_node(x,d)
  node *x; /* an old node that the new node will call |prev| */
  int d; /* incremental change to |len| */
{
  if (next_node==bad_node) {
    next_node=gb_alloc_type(1000,@[node@],node_storage);
    if (next_node==NULL) return NULL; /* we're out of space */
    bad_node=next_node+1000;
  }
  next_node->prev=x;
  next_node->len=(x?x->len:0)+d;
  return next_node++;
}

@ @<Recycle the auxiliary memory used@>=
gb_free(node_storage);

@ When we're done, |cur_node->a->tip| will be the |goal| vertex, and
we can get back to the |start| vertex by following |prev| links
from |cur_node|. It looks better to print the answers from |start| to
|goal|, so maybe we should have changed our algorithm to go the
other way.

But let's not worry over trifles. It's easy to change
the order of a linked list. The secret is simply to think of the list
as a stack, from which we pop all the elements off to another stack;
the new stack has the elements in reverse order.

@<Print the solution corresponding to |cur_node|@>=
next_node=NULL; /* now we'll use |next_node| as top of temporary stack */
do@+{@+register node*t;
  t=cur_node;
  cur_node=t->prev; /* pop */
  t->prev=next_node;
  next_node=t; /* push */
}@+while (cur_node);
for (v=start;v!=goal;v=u,next_node=next_node->prev) {
  a=next_node->a;
  u=a->tip;
  @<Print the score of game |a| between |v| and |u|@>;
  printf(" (%+d)\n",next_node->len);
}

@ @<Print the score of game |a| between |v| and |u|@>=
{@+register int d=a->date; /* date of the game, 0 means Aug 26 */
  if (d<=5) printf(" Aug %02d",d+26);
  else if (d<=35) printf(" Sep %02d",d-5);
  else if (d<=66) printf(" Oct %02d",d-35);
  else if (d<=96) printf(" Nov %02d",d-66);
  else if (d<=127) printf(" Dec %02d",d-96);
  else printf(" Jan 01"); /* |d=128| */
  printf(": %s %s %d, %s %s %d",v->name,v->nickname,a->len,
                                u->name,u->nickname,a->len-a->del);
}

@ We can't just move from |v| to any adjacent vertex; we can only
go to a vertex from which |goal| can be reached without touching |v|
or any other vertex already used on the path from |start|.

Furthermore, if the locally best move from |v| is directly to |goal|,
we don't want to make that move unless it's our last chance; we can
probably do better by making the chain longer. Otherwise, for example,
a chain between a team and its worst opponent would consist of
only a single game.

To keep track of untouchable vertices, we use a utility field
called |blocked| in each vertex record. Another utility field,
|valid|, will be set to a validation code in each vertex that
still leads to the goal.

@d blocked u.i
@d valid v.v

@<Use a simple-minded greedy algorithm to find a chain from |start| to |goal|@>=
{
  for (v=g->vertices;v<g->vertices+g->n;v++) v->blocked=0,v->valid=NULL;
  cur_node=NULL;
  for (v=start;v!=goal;v=cur_node->a->tip) {@+register int d=-10000;
    register Arc *best_arc; /* arc that achieves |del=d| */
    register Arc *last_arc; /* arc that goes directly to |goal| */
    v->blocked=1;
    cur_node=new_node(cur_node,0);
    if (cur_node==NULL) {
      fprintf(stderr,"Oops, there isn't enough memory!\n");@+return -2;
    }
    @<Set |u->valid=v| for all |u| to which |v| might now move@>;
    for (a=v->arcs;a;a=a->next)
      if (a->del>d && a->tip->valid==v)
        if (a->tip==goal) last_arc=a;
        else best_arc=a,d=a->del;
    cur_node->a=(d==-10000?last_arc:best_arc);
                 /* use |last_arc| as a last resort */
    cur_node->len+=cur_node->a->del;
  }
}

@ A standard marking algorithm supplies the final missing link in
our algorithm.

@d link w.v

@<Set |u->valid=v| for all |u| to which |v| might now move@>=
u=goal; /* |u| will be the top of a stack of nodes to be explored */
u->link=NULL;
u->valid=v;
do {
  for (a=u->arcs,u=u->link;a;a=a->next)
    if (a->tip->blocked==0 && a->tip->valid!=v) {
      a->tip->valid=v; /* mark |a->tip| reachable from |goal| */
      a->tip->link=u;
      u=a->tip; /* push it on the stack, so that its successors
                   will be marked too */
    }
} while (u);

@*Stratified greed.
One approach to better chains is the following algorithm, motivated by
similar ideas of Pang Chen [Ph.D. thesis, Stanford University, 1989]:
Suppose the nodes of a (possibly huge) backtrack tree are classified into
a (fairly small) number of strata, by a function $h$ with the property
that $h({\rm child})<h({\rm parent})$. Suppose further that we wish to
find a node $x$ that maximizes a given function~$f(x)$, where it is
reasonable to believe that $f$(child) will be relatively large among
nodes in a child's stratum only if $f$(parent) is relatively large in
the parent's stratum. Then it makes sense to restrict backtracking to,
say, the top $w$ nodes of each stratum, ranked by their $f$ values.

The greedy algorithm already described is a special case of this general
approach, with $w=1$ and with $h(x)=-($length of chain leading to~$x)$.
The refined algorithm we are about the describe uses a general value of $w$
and a somewhat more relevant stratification function: Given a node~$x$
of the backtrack tree for longest paths, corresponding to a path from
|start| to a certain vertex~$u=u(x)$, we will let $h(x)$ be the number of
vertices that lie between |u| and |goal| (in the sense that the simple
path from |start| to~|u| can be extended until it passes through such
a vertex and then all the way to~|goal|).

Here is the top level of the stratified greedy algorithm. We maintain
a linked list of nodes for each stratum, i.e., for each possible value
of~$h$. The number of nodes required is bounded by $w$ times the
number of strata.

@<Use a strat...@>=
{
  @<Make |list[0]| through |list[n-1]| empty@>;
  cur_node=NULL; /* |NULL| represents the root of the backtrack tree */
  m=g->n-1; /* the highest stratum not yet fully explored */
  do@+{
    @<Place each child~|x| of |cur_node| into |list[h(x)]|, retaining
      at most |width| nodes of maximum |len| on each list@>;
    while (list[m]==NULL) m--,mm=0;
    cur_node=list[m];
    list[m]=cur_node->next; /* remove a node from highest remaining stratum */
    if (verbose) @<Print ``verbose'' info about |cur_node|@>;
  }@+while (m>0); /* exactly one node should be in |list[0]| (see below) */
}

@ The calculation of $h(x)$ is somewhat delicate, and we will defer it
for a moment. The list manipulation is, however, easy, so we can finish it
quickly while it's fresh in our minds.

@d MAX_N 120 /* the number of teams in \.{games.dat} */

@<Glob...@>=
node *list[MAX_N]; /* the best nodes known in given strata */
int size[MAX_N]; /* the number of elements in a given |list| */
int m,h; /* current lists of interest */
node *x; /* a child of |cur_node| */

@ @<Make |list[0]|...@>=
for (m=0;m<g->n;m++) {
  list[m]=NULL;
  size[m]=0;
}

@ The lists are maintained in order by |len|, with the largest |len| value
at the end so that we can easily delete the smallest.

When |h=0|, we retain only one node instead of~|width| different nodes,
because we are interested in only one solution.

@<Place node~|x| into |list[h]|, retaining
    at most |width| nodes of maximum |len|@>=
if ((h>0 && size[h]==width) || (h==0 && size[0]>0)) {
  if (x->len<=list[h]->len) goto done; /* drop node |x| */
  list[h]=list[h]->next; /* drop one node from |list[h]| */
} else size[h]++;
{@+register node *p,*q; /* node in list and its predecessor */
  for (p=list[h],q=NULL; p; q=p,p=p->next)
    if (x->len<=p->len) break;
  x->next=p;
  if (q) q->next=x;
  else list[h]=x;
}
done:;

@ @<Print ``verbose'' info...@>=
{
  cur_node->next=(node*)((++mm<<8)+m); /* pack an ID for this node */
  printf("[%d,%d]=[%d,%d]&%s (%+d)\n",m,mm,@|
    cur_node->prev?((unsigned)cur_node->prev->next)&0xff:0,@|
    cur_node->prev?((unsigned)cur_node->prev->next)>>8:0,@|
    cur_node->a->tip->name, cur_node->len);
}

@ Incidentally, it is plausible to conjecture that the stratified algorithm
always beats the simple greedy algorithm; but that conjecture is false.
For example, the greedy algorithm is able to rank Harvard over Stanford
by 1529, while the stratified algorithm achieves only 1527 when
|width=1|. On the other hand, the greedy algorithm often fails
miserably; when comparing two Ivy League teams, it doesn't find a
way to break out of the Ivy and Patriot Leagues.

@*Bicomponents revisited.
How difficult is it to compute the function $h$? Given a connected graph~$G$
with two distinguished vertices $u$ and~$v$, we wish to count the number
of vertices that might appear on a simple path from $u$ to~$v$.
(This is {\it not\/} the same as the number of vertices reachable from both
$u$ and~$v$. For example, consider a ``claw'' graph with four vertices
$\{u,v,w,x\}$ and with edges only from $x$ to the other three vertices;
in this graph $w$ is reachable from $u$ and~$v$ but it is not on any simple
path between them.)

The best way to solve this problem is probably to compute the bicomponents
of~$G$, or least to compute some of them. Another demo program,
|book_components|, explains the relevant theory in some detail, and
we will assume familiarity with that algorithm in the present
discussion.

Let us imagine extending $G$ to a slightly larger graph $G^+$ by
adding a dummy vertex~$o$ that is adjacent only to $v$. Suppose we determine
the bicomponents of $G^+$ by depth-first search starting at~$o$.
These bicomponents form a tree rooted at the bicomponent that contains
just $o$ and~$v$. The number of vertices on paths between $u$ and~$v$,
not counting $v$ itself, is then the number of vertices in the bicomponent
containing~$u$ and in any other bicomponents between that one and the root.

Strictly speaking, each articulation point belongs
to two or more bicomponents. But we will assign each articulation point
to its bicomponent that is nearest the root of the tree; then the vertices
of each bicomponent are precisely the vertices output in bursts by the
depth-first procedure. The bicomponents we wish to enumerate are $B_1$, $B_2$,
\dots,~$B_k$, where $B_1$ is the bicomponent containing~$u$ and
$B_{j+1}$ is the bicomponent containing the articulation point associated
with~$B_j$; we stop at~$B_k$ when its associated articulation point is~$v$.
(Often $k=1$.)

The ``children'' of a given graph~$G$ are obtained by removing vertex~$u$
and by considering paths from $u'$ to~$v$, where $u'$ is a vertex
formerly adjacent to~$u$; thus $u'$ is either in~$B_1$ or it is $B_1$'s
associated articulation point. Removing $u$ will, in general, split
$B_1$ into a tree of smaller bicomponents, but $B_2,\ldots,B_k$ will be
unaffected. The implementation below does not take full advantage of this
observation, because the amount of memory required to avoid recomputation
would probably be prohibitive.

@ The following program is copied almost verbatim from |book_components|.
Instead of repeating the commentary that appears there, we will mention
only the significant differences. One difference is that we start
the depth-first search at a definite place, the |goal|.

@<Place each child~|x| of |cur_node| into |list[h(x)]|, retaining
    at most |width| nodes of maximum |len| on each list@>=
@<Make all vertices unseen and all arcs untagged, except for vertices
  that have already been used in steps leading up to |cur_node|@>;
@<Perform a depth-first search with |goal| as the root, finding
  bicomponents and determining the number of vertices accessible
  between any given vertex and |goal|@>;
for (a=(cur_node? cur_node->a->tip: start)->arcs; a; a=a->next)
  if ((u=a->tip)->untagged==NULL) { /* |goal| is reachable from |u| */
    x=new_node(cur_node,a->del);
    if (x==NULL) {
      fprintf(stderr,"Oops, there isn't enough memory!\n");@+return -3;
    }
    x->a=a;
    @<Set |h| to the number of vertices on paths between |u| and |goal|@>;
    @<Place node...@>;
  }

@ Setting the |rank| field of a vertex to infinity, before beginning
a depth-first search, is tantamount to removing that vertex from
the graph, because it tells the algorithm not to look further at
such a vertex.

@d rank z.i /* when was this vertex first seen? */
@d parent u.v /* who told me about this vertex? */
@d untagged x.a /* what is its first untagged arc? */
@d min v.v /* how low in the tree can we jump from its mature descendants? */

@<Make all vertices unseen and all arcs untagged, except for vertices
  that have already been used in steps leading up to |cur_node|@>=
for (v=g->vertices; v<g->vertices+g->n; v++) {
  v->rank=0;
  v->untagged=v->arcs;
}
for (x=cur_node;x;x=x->prev)
  x->a->tip->rank=g->n; /* ``infinite'' rank (or close enough) */
start->rank=g->n;
nn=0;
active_stack=settled_stack=NULL;

@ @<Glob...@>=
Vertex * active_stack; /* the top of the stack of active vertices */
Vertex *settled_stack; /* the top of the stack of bicomponents found */
int nn; /* the number of vertices that have been seen */
Vertex dummy; /* imaginary parent of |goal|; its |rank| is zero */

@ The |settled_stack| will contain a list of all bicomponents in
the opposite order from which they are discovered. This is the order
we need for computing the |h| function in each bicomponent later.

@<Perform a depth-first search...@>=
{
  v=goal;
  v->parent=&dummy;
  @<Make vertex |v| active@>;
  do @<Explore one step from the current vertex~|v|, possibly moving
        to another current vertex and calling~it~|v|@>@;
  while (v!=&dummy);
  @<Use |settled_stack| to put the mutual reachability count for
     each vertex |u| in |u->parent->rank|@>;
}

@ @<Make vertex |v| active@>=
v->rank=++nn;
v->link=active_stack;
active_stack=v;
v->min=v->parent;

@ @<Explore one step from the current vertex~|v|, possibly moving
        to another current vertex and calling~it~|v|@>=
{@+register Vertex *u; /* a vertex adjacent to |v| */
  register Arc *a=v->untagged; /* |v|'s first remaining untagged arc, if any */
  if (a) {
    u=a->tip;
    v->untagged = a->next; /* tag the arc from |v| to |u| */
    if (u->rank) { /* we've seen |u| already */
      if (u->rank < v->min->rank)
        v->min=u; /* non-tree arc, just update |v->min| */
    } else { /* |u| is presently unseen */
      u->parent = v; /* the arc from |v| to |u| is a new tree arc */
      v = u; /* |u| will now be the current vertex */
      @<Make vertex |v| active@>;
    }
  } else { /* all arcs from |v| are tagged, so |v| matures */
    u=v->parent; /* prepare to backtrack in the tree */
    if (v->min==u) @<Remove |v| and all its successors on the active stack
         from the tree, and report them as a bicomponent of the graph
         together with~|u|@>@;
    else  /* the arc from |u| to |v| has just matured,
             making |v->min| visible from |u| */@,
      if (v->min->rank < u->min->rank)
        u->min=v->min;
    v=u; /* the former parent of |v| is the new current vertex |v| */
  }
}

@ When a bicomponent is found, we reset the |parent| field of each vertex
so that, afterwards, two vertices will belong to the same bicomponent
if and only if they have the same |parent|. (This trick was not used
in |book_components|, but it does appear in the similar algorithm of
|roget_components|.) The new parent, |v|, will represent that bicomponent
in subsequent computation; we put it onto |settled_stack|.
We also reset |v->rank| to be the bicomponent's size, plus a constant
large enough to keep the algorithm from getting confused. (Vertex~|u|
may still have untagged arcs leading into this bicomponent; we need to
keep the ranks at least as big as the rank of |u->min|.) Notice that
|v->min| is |u|, the articulation point associated with this bicomponent.
Later the |rank| field will
contain the sum of all counts between here and the root.

We don't have to do anything when |v==goal|; the trivial root bicomponent
always comes out last.

@<Remove |v| and all its successors on the active stack...@>=
{@+if (v!=goal) {@+register Vertex *t; /* runs through the vertices of the
                          new bicomponent */
    int c=0; /* the number of vertices removed */
    t=active_stack;
    while (t!=v) {
      c++;
      t->parent=v;
      t=t->link;
    }
    active_stack=v->link;
    v->parent=v;
    v->rank=c+g->n; /* the true component size is |c+1| */
    v->link=settled_stack;
    settled_stack=v;
  }
}

@ So here's how we sum the ranks. When we get to this step, the |settled|
stack contains all bicomponent representatives except |goal| itself.

@<Use |settled_stack| to put the mutual reachability count for
     each vertex |u| in |u->parent->rank|@>=
while (settled_stack) {
  v=settled_stack;
  settled_stack=v->link;
  v->rank+=v->min->parent->rank+1-g->n;
} /* note that |goal->parent->rank=0| */

@ And here's the last piece of the puzzle.

@<Set |h| to the number of vertices on paths between |u| and |goal|@>=
h=u->parent->rank;

@* Index. Finally, here's a list that shows where the identifiers of this
program are defined and used.

