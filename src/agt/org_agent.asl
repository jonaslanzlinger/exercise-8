// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

has_enough_players_for(R) :-
  role_cardinality(R,Min,Max) &
  .count(play(_,R,_),NP) &
  NP >= Min.

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
  .print("Hello world");
  // create the workspace "lab_monitoring_org" and join it
  createWorkspace(OrgName);
  joinWorkspace(OrgName, WorkspaceId);
  // create the OrgBoard artifact and focus it
  makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgBoardArtId);
  focus(OrgBoardArtId);
  // create the GroupArt "monitoring_team" and focus on it
  createGroup(GroupName, GroupName, GroupArtId);
  focus(GroupArtId);
  // create the SchemeArt "monitoring_scheme" and focus on it
  createScheme(SchemeName, SchemeName, SchemeArtId);
  focus(SchemeArtId);

  // broadcast the information that a new organization has been created
  .broadcast(tell, org_created(OrgName));

  !inspect(GroupArtId); // inspect the Group artifact
  !inspect(SchemeArtId); // inspect the Scheme artifact

  .wait(15000);
  !complete_group_formation(GroupArtId).

+!complete_group_formation(G) : formationStatus(nok) & group(GroupName,_,G)[artifact_id(OrgId)] & scheme(SchemeName, SchemeType, SchemeArtId) & specification(S)[artifact_id(G)] & org_name(OrgName) <-
  .print("Waiting for group ", GroupName," to become well-formed");

  if (not has_enough_players_for(temperature_reader)) {
    .print("Not enough players for role temperature_reader");
    .broadcast(tell, ask_fulfill_role(temperature_reader, "lab_monitoring_org"));
  }
  else {
    .print("Enough players for role temperature_reader");
  }
  if (not has_enough_players_for(temperature_manifestor)) {
    .print("Not enough players for role temperature_manifestor");
    .broadcast(tell, ask_fulfill_role(temperature_manifestor, "lab_monitoring_org"));
  }
  else {
    .print("Enough players for role temperature_manifestor");
  }

  // .findall(Role, play(_, Role, G), Roles);
  .wait(15000);
  !complete_group_formation(GroupArtId).
  // .wait({+formationStatus(ok)[artifact_id(G)]}). // waits until the belief is added in the belief base

+!complete_group_formation(G) : true <-
  .print("Group ", G, " is well-formed and can work on the scheme.").

+formationStatus(ok)[artifact_id(G)] : group(GroupName,_,G)[artifact_id(OrgName)] & scheme(SchemeId, SchemeType, ArtId) <-
  .print("Group ", GroupName, " is well-formed and can work on the scheme.");
  addScheme(SchemeId)[artifact_id(G)].

/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }