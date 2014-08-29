/*
@Title LC assets replacement tracker - RMA things
@Author Victor Wong
@Since 29/08/2014
*/
lcrp_selected = lcrp_selected_user = last_trk_lbid = "";
last_lb_holder = last_trk_rec = null;

Object getLCReplace_track_rec(String iwhat)
{
	sqlstm = "select * from rw_lc_replacements where origid=" + iwhat;
	return sqlhand.gpSqlFirstRow(sqlstm);
}

void lcrepDo(String itype, String ifc6)
{
	todaydate =  kiboo.todayISODateTimeString();
	refresh = false;
	sqlstm = msgtext = "";
	unm = useraccessobj.username;
	Object[] jkl = { v_lc_id, v_in_assettag, v_out_assettag, v_action, v_act_date};

	if( ifc6 == null ) return;
	if( ifc6.equals("")) return;

	if(itype.equals("updlcrep_b"))
	{
		dt = ngfun.getString_fromUI(jkl);

		if(lcrp_selected.equals("")) // new insert
		{
			sqlstm = "insert into rw_lc_replacements (fc6_custid,username,lc_id,in_assettag,out_assettag,action,act_date) values " +
			"('" + ifc6 + "','" + unm + "','" + dt[0] + "','" + dt[1] + "','" + dt[2] + "','" + dt[3] + "','" + dt[4] + "')";
			ngfun.clearUI_Field(jkl);
		}
		else
		{
			sqlstm = "update rw_lc_replacements set lc_id='" + dt[0] + "',in_assettag='" + dt[1] + "',out_assettag='" + dt[2] + "'," +
			"action='" + dt[3] + "', act_date='" + dt[4] + "' where origid=" + lcrp_selected;
		}
	}

	if(itype.equals("remlcrep_b")) // delete LC-replacement track
	{
		if(lcrp_selected.equals("")) return;
		if(!lcrp_selected_user.equals(unm)) msgtext = "Sorry, you're not the owner of this record";
		else
		{
			if(Messagebox.show("Remove this LC-replacement track record..", "Are you sure?", 
				Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) !=  Messagebox.YES) return;

			sqlstm = "delete from rw_lc_replacements where origid=" + lcrp_selected;
		}
	}

	if(itype.equals("clrlcrep_b"))
	{
		ngfun.clearUI_Field(jkl);
		lcrp_selected = "";
	}

	if(!sqlstm.equals(""))
	{
		sqlhand.gpSqlExecuter(sqlstm);
		showLCAss_RepTrack(last_trk_rec,last_lb_holder,last_trk_lbid);
	}
	if(!msgtext.equals("")) guihand.showMessageBox(msgtext);
}

void showLCRep_metadata(String iwhat)
{
	r = getLCReplace_track_rec(iwhat);
	if(r == null) return;
	Object[] jkl = { v_lc_id, v_in_assettag, v_out_assettag, v_act_date, v_action };
	String[] fl = { "lc_id", "in_assettag", "out_assettag", "act_date", "action" };
	ngfun.populateUI_Data(jkl,fl,r);
}

Object[] lcasrephds = 
{
	new listboxHeaderWidthObj("origid",false,""),
	new listboxHeaderWidthObj("LC.Id",true,"50px"),
	new listboxHeaderWidthObj("I.Asset",true,"60px"),
	new listboxHeaderWidthObj("Replace",true,"60px"),
	new listboxHeaderWidthObj("User",true,"60px"),
	new listboxHeaderWidthObj("Stat",true,"40px"),
	new listboxHeaderWidthObj("GCO",true,"40px"),
	new listboxHeaderWidthObj("Act",true,""),
	new listboxHeaderWidthObj("A.Date",true,"70px"),
};

class lcasrepClick implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		lcrp_selected = lbhand.getListcellItemLabel(isel,0);
		lcrp_selected_user = lbhand.getListcellItemLabel(isel,4);
		showLCRep_metadata(lcrp_selected);
	}
}
lcassrepcliker = new lcasrepClick();

void showLCAss_RepTrack(Object itkr, Div idiv, String lbid)
{
	last_trk_lbid = lbid; last_trk_rec = itkr; last_lb_holder = idiv;

	Listbox newlb = lbhand.makeVWListbox_Width(idiv, lcasrephds, lbid, 3);
	fc6 = itkr.get("fc6_custid");
	if(fc6 == null) return;

	sqlstm = "select * from rw_lc_replacements where fc6_custid='" + fc6 + "'";
	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	newlb.setRows(21); newlb.setMold("paging");
	newlb.addEventListener("onSelect", lcassrepcliker);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid","lc_id","in_assettag","out_assettag","username","rstatus","gco_id","action","act_date" };
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}
