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
	new listboxHeaderWidthObj("LC.Id",true,"90px"),
	new listboxHeaderWidthObj("origid",false,""),
	new listboxHeaderWidthObj("I.Asset",true,"60px"),
	new listboxHeaderWidthObj("Replace",true,"60px"),
	new listboxHeaderWidthObj("User",true,"60px"),
	new listboxHeaderWidthObj("Stat",true,"40px"), // to be updated by BA
	new listboxHeaderWidthObj("GCO",true,"40px"),
	new listboxHeaderWidthObj("G.Stat",true,"50px"),
	new listboxHeaderWidthObj("Act",true,""),
	new listboxHeaderWidthObj("A.Date",true,"70px"),
};
LCIDPOS = 0;
ORIGPOS = 1;
INRECASSET = 2;
GCOPOS = 6;

class lcasrepClick implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		try {
		isel = event.getReference();
		lcrp_selected = lbhand.getListcellItemLabel(isel,ORIGPOS);
		lcrp_selected_user = lbhand.getListcellItemLabel(isel,4);
		showLCRep_metadata(lcrp_selected);
		} catch (Exception e) {}
	}
}
lcassrepcliker = new lcasrepClick();

void showLCAss_RepTrack(Object itkr, Div idiv, String lbid)
{
	last_trk_lbid = lbid; last_trk_rec = itkr; last_lb_holder = idiv;

	Listbox newlb = lbhand.makeVWListbox_Width(idiv, lcasrephds, lbid, 3);
	fc6 = itkr.get("fc6_custid");
	if(fc6 == null) return;

	sqlstm = "select *, (select status from rw_goodscollection where CONVERT(varchar(10),origid)=rlr.gco_id) as gstat from rw_lc_replacements rlr where fc6_custid='" + fc6 + "' order by origid desc";
	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	newlb.setRows(21); newlb.setMold("paging");
	newlb.setMultiple(true); newlb.setCheckmark(true);
	newlb.addEventListener("onSelect", lcassrepcliker);
	ArrayList kabom = new ArrayList();
	String[] fl = { "lc_id","origid","in_assettag","out_assettag","username","rstatus","gco_id","gstat", "action","act_date" };
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

// Save selected LC/assets transient make GCO
void saveLCrep_GCO()
{
	tlb = last_lb_holder.getFellowIfAny(last_trk_lbid);
	if(tlb == null) return;
	if(tlb.getSelectedCount() == 0) return;
	if(glob_selected_ticket.equals("")) return;
	sqlstm = "";

	if(global_selected_customerid.equals("")) { guihand.showMessageBox("ERR: customer ID not assigned"); return; }

	for(d : tlb.getSelectedItems())
	{
		atg = lbhand.getListcellItemLabel(d,INRECASSET);
		lci = lbhand.getListcellItemLabel(d,LCIDPOS);
		if(atg.equals("")) continue;

		gcni = lbhand.getListcellItemLabel(d,GCOPOS); // gcn-id must be blank to be saved in transient-table
		if(gcni.equals("") || gcni.equals("0"))
		{
			sqlstm += "insert into rw_gcn_transient (lc_id,serial_no,asset_tag,item_desc,fc6_custid,csv_id) values " +
			"('" + lci + "','','" + atg + "','','" + global_selected_customerid + "','" + glob_selected_ticket + "');";
		}
	}
	sqlhand.gpSqlExecuter(sqlstm);
	guihand.showMessageBox("Assets saved for GCO");
}
