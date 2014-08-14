// RW assignment-drawdown funcs -- used in rwBilling.zul

void assignmentFunc(String itype)
{
	todaydate =  kiboo.todayISODateTimeString();
	refresh = false;
	msgtext = sqlstm = "";

	if(itype.equals("asg_remove_b"))
	{
		if(assignments_lb.getSelectedCount() == 0) return;

		if(Messagebox.show("Remove LC(s) from assignment juggler..", "Are you sure?", 
			Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) !=  Messagebox.YES) return;

		kr = getAssignment_LC_notassigned();
		if(kr == null) return;
		sqlstm = "delete from rw_assignment where origid in (" + kr + ");";
		refresh = true;
	}

	if(itype.equals("asg_toggleasgna_b")) // admin func
	{
		if(assignments_lb.getSelectedCount() == 0) return;
		kr = assignments_lb.getSelectedItems().toArray();
		aa = "";
		for(i=0; i<kr.length; i++)
		{
			d = lbhand.getListcellItemLabel(kr[i],LCID_IDX);
			aa += "'" + d + "',";
		}
		try { aa = aa.substring(0,aa.length()-1); } catch (Exception e) {}

		sqlstm = "update rw_lc_records set assigned=1-assigned where lc_id in (" + aa + ");";
		refresh = true;
	}

	if(itype.equals("asg_clrgroupi_b")) // admin func
	{
		kr = getAssignment_LC_notassigned();
		if(kr == null) return;
		sqlstm = "update rw_assignment set groupi=null where origid in (" + kr + ");";
		refresh = true;
	}

	if(itype.equals("asg_coverlet_b"))
	{
		kr = getAssignment_LC_notassigned();
		if(kr == null) return;
		mgx = getTopGroupi();
		sqlstm = "update rw_assignment set groupi=" + mgx + " where origid in (" + kr + ");";
		refresh = true;
	}

	if(itype.equals("asg_noa_b"))
	{
	}

	if(itype.equals("asg_assetslisting_b"))
	{
	}

	if(!sqlstm.equals("")) sqlhand.gpSqlExecuter(sqlstm);
	if(refresh) showAssignmentJuggler();
	if(!msgtext.equals("")) guihand.showMessageBox(msgtext);
}

String getTopGroupi()
{
	sqlstm = "select case when max(groupi) is null then 1 else max(groupi) + 1 end as maxgpi from rw_assignment;";
	r = sqlhand.gpSqlFirstRow(sqlstm);
	return (r == null) ? "1" : r.get("maxgpi").toString();
}

// return entries in rw_assignment not assigned
String getAssignment_LC_notassigned()
{
	if(assignments_lb.getSelectedCount() == 0) return null;
	kr = assignments_lb.getSelectedItems().toArray();
	aa = "";
	for(i=0; i<kr.length; i++)
	{
		nn = lbhand.getListcellItemLabel(kr[i],ASGNFLAG_IDX);
		if(nn.equals("N"))
		{
			aa += lbhand.getListcellItemLabel(kr[i],ASGNID_IDX) + ",";
		}
	}
	try { aa = aa.substring(0,aa.length()-1); } catch (Exception e) {}
	return aa;
}

void assignmentCreate()
{
	if(mainlc_tree.getSelectedCount() == 0) return;
	ki = mainlc_tree.getSelectedItems().toArray();
	sqlstm = "";
	for(i=0; i<ki.length; i++)
	{
		mi = ki[i].getChildren().toArray();
		for(j=0; j<mi.length; j++)
		{
			if(mi[j] instanceof Treerow)
			{
				ba = mi[j].getChildren().toArray();
				atg = ba[0].getLabel();
				cnm = ba[1].getLabel();
				sqlstm += "If Not Exists(select origid from rw_assignment where lc_id='" + atg + "') Begin " + 
				"insert into rw_assignment (lc_id,datecreated,customer_name) values ('" + atg + "','" + kiboo.todayISODateTimeString() +"','" + cnm + "') End;";
			}
		}
	}

	if(!sqlstm.equals(""))
	{
		sqlhand.gpSqlExecuter(sqlstm);
		mainlc_tree.clearSelection();
		showAssignmentJuggler();
		guihand.showMessageBox("LC/RWs inserted into assignment juggler..");
	}
}

class asgndoublecliker implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		selitem = event.getTarget();
		//glob_sel_audit = lbhand.getListcellItemLabel(selitem,0);
		assignmentMeta_pop.open(selitem);
	}
}
asgnboudbleciker = new asgndoublecliker();

Object[] rwassgnhds =
{
	new listboxHeaderWidthObj("REC",true,"60px"),
	new listboxHeaderWidthObj("GRP",true,"60px"),
	new listboxHeaderWidthObj("Dated",true,"70px"),
	new listboxHeaderWidthObj("LC/RW",true,"70px"),
	new listboxHeaderWidthObj("Customer",true,""),
	new listboxHeaderWidthObj("Amount",true,"80px"),
	new listboxHeaderWidthObj("NOA",true,"70px"),
	new listboxHeaderWidthObj("C.Let",true,"70px"),
	new listboxHeaderWidthObj("DrawD",true,"70px"),
	new listboxHeaderWidthObj("DrawA",true,"80px"),
	new listboxHeaderWidthObj("F/Ref",true,"100px"),
	new listboxHeaderWidthObj("ASGN",true,"50px"), // 11
};
ASGNID_IDX = 0;
GRP_IDX = 1;
LCID_IDX = 3;
ASGNFLAG_IDX = 11;

void showAssignmentJuggler()
{
	Listbox newlb = lbhand.makeVWListbox_Width(asgn_holder, rwassgnhds, "assignments_lb", 5);
	sqlstm = "select rwa.origid, rwa.datecreated, rwa.lc_id, rwa.customer_name, rwa.groupi, " +
	"rwa.noa_submit, rwa.coverletter_submit, rwa.draw_date, rwa.draw_amount, rwa.financer_ref, " +
	"rwl.assigned, rwl.rm_contract " + 
	"from rw_assignment rwa " +
	"left join rw_lc_records rwl on ltrim(rtrim(rwa.lc_id)) = ltrim(rtrim(rwl.lc_id)) " +
	"order by rwa.origid desc";

	r = sqlhand.gpSqlGetRows(sqlstm);
	if(r.size() == 0) return;
	newlb.setRows(21);
	newlb.setMold("paging");
	newlb.setMultiple(true);
	newlb.setCheckmark(true);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "groupi", "datecreated", "lc_id", "customer_name", "rm_contract", 
	"noa_submit", "coverletter_submit", "draw_date", "draw_amount", "financer_ref", "assigned" };
	for(d : r)
	{
		popuListitems_Data(kabom,fl,d);
		sty = "";
		if(d.get("assigned")) sty = "font-size:9px;background:#3DB9DB";
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false",sty);
		kabom.clear();
	}
	lbhand.setDoubleClick_ListItems(newlb, asgnboudbleciker);
}