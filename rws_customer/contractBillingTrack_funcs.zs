import org.victor.*;
// GP funcs for contractBillingTrack.zul

// chk if asset already in LC - dups-check. Return LC-id
String assetExistInLC(String iastg)
{
	retv = "";
	sqlstm = "select lc_parent from rw_lc_equips where asset_tag='" + iastg + "' order by lc_parent desc";
	kr = sqlhand.gpSqlFirstRow(sqlstm);
	if(kr != null) retv = kr.get("lc_parent").toString();
	return retv;
}

// check asset-tag already link to LC
// retv: 0=not-found, 1=no LC-id linked, 2=already linked to LC
int assetLinkToLC(String iastg)
{
	retv = 0;
	sqlstm = "select lc_id from stockmasterdetails where stock_code='" + iastg + "'";
	kr = sqlhand.gpSqlFirstRow(sqlstm);
	if(kr == null) return retv;
	if(kr.get("lc_id") == null) retv = 1;
	else retv = 2;
	return retv;
}

// Get value from textbox/datebox as concatenated-string separated TODO other mods have similar func, make them use this
// icol=which column, isepa=separator
String concatRowsComp_str(int icol, String isepa, Object irows)
{
	cds = irows.getChildren().toArray();
	retv = "";

	for(i=0; i<cds.length; i++)
	{
		c1 = cds[i].getChildren().toArray();

		if(c1[icol] instanceof Textbox)
			retv += kiboo.replaceSingleQuotes( c1[icol].getValue().replaceAll(isepa," ") ) + isepa;

		if(c1[icol] instanceof Datebox)
			retv += kiboo.getDateFromDatebox( c1[icol] ) + isepa;
	}

	try { retv = retv.substring(0,retv.length()-1); } catch (Exception e) {}
	return retv;
}

// TODO some modules have similar func, make them use this general-purpose one
void makeLinkThingsGrid(Div iholder, String igrid, String irowsid, String[] icolws, String[] icolls, String istyle)
{
	if(iholder.getFellowIfAny(igrid) == null) // make new grid if none
	{
		igrd = new Grid();
		igrd.setId(igrid);

		icols = new org.zkoss.zul.Columns();
		for(i=0;i<icolws.length;i++)
		{
			ico0 = new org.zkoss.zul.Column();
			ico0.setWidth(icolws[i]);
			ico0.setLabel(icolls[i]);
			//if(i != 1 || i != 2) 
			ico0.setAlign("center");
			if(!istyle.equals("")) ico0.setStyle(istyle);
			ico0.setParent(icols);
		}
		icols.setParent(igrd);
		irows = new org.zkoss.zul.Rows();
		irows.setId(irowsid);
		irows.setParent(igrd);
		igrd.setParent(iholder);
	}
}

// TODO some modules have similar func, make them use this general-purpose one
void removeRowFromGrid(Object irows)
{
	cds = irows.getChildren().toArray();
	if(cds.length < 1) return;
	for(i=0; i<cds.length; i++)
	{
		c1 = cds[i].getChildren().toArray();
		if(c1[0].isChecked()) cds[i].setParent(null);
	}
}

// Hide all and show only iwhat
void showHideFuncBar(Object iwhat)
{
	Div[] allfuncbars = { assets_func_bar };
	for(i=0; i<allfuncbars.length; i++)
	{
		allfuncbars[i].setVisible(false);
	}

	iwhat.setVisible(true);
}

void showLCMetadata(String iwhat)
{
	lcr = getLCNew_rec(iwhat);
	glob_lcmeta_rec = lcr; // later use
	if(lcr == null) { guihand.showMessageBox("DBERR: cannot access LC table"); return; }

	clearLCMetaFields();

	recnum_lbl.setValue("Record: " + iwhat);

	String[] flns = {
	"lc_id", "rocno", "rwno", "fc6_custid", "customer_name", "remarks", "order_type", "product_name",
	"fina_ref", "co_assigned_name", "co_do_ref", "co_master_lc", "co_inv_to_financer", "prev_lc", "prev_roc", "charge_out",
	"cust_project_id", "noa_no", "lstartdate", "lenddate", "charge_out_date", "period", "inst_type", "invoice_date", "batch_lc"
	};

	Object[] ibx = {
	i_lc_no, i_rocno, i_rwno, l_fc6_custid, customername, i_remarks, i_order_type, i_product_name,
	i_fina_ref, i_co_assigned_name, i_co_do_ref, i_co_master_lc, i_co_inv_to_financer, i_prev_lc, i_prev_roc, i_charge_out,
	i_cust_project_id, i_noa_no, i_lstartdate, i_lenddate, i_charge_out_date, i_period, i_inst_type, i_invoice_date, i_batch_lc
	};

	ngfun.populateUI_Data(ibx, flns, lcr);

	iass = (lcr.get("assigned") == null) ? "NO" : ( (lcr.get("assigned")) ? "YES" : "NO" );
	lbhand.matchListboxItems(i_assigned, iass );

	String[] fln2 = {
	"rm_month", "rm_contract", "qty_dt", "qty_mt", "qty_nb", "qty_pt", "qty_hs", "qty_ms",
	"charge_out_period", "co_instalment_count", "co_due_date",
	"fina_amount", "co_monthly_rental", "co_deposit", "co_recv_ex_deposit", "co_recv_in_deposit",
	"co_pv_drawdown", "co_pv_drawdown_ex_deposit", "co_assigned_interest",
	};

	Object[] ibx2 = {
	i_rm_month, i_rm_contract, i_qty_dt, i_qty_mt, i_qty_nb, i_qty_pt, i_qty_hs, i_qty_ms,
	i_charge_out_period, i_co_instalment_count, i_co_due_date,
	i_fina_amount, i_co_monthly_rental, i_co_deposit, i_co_recv_ex_deposit, i_co_recv_in_deposit,
	i_co_pv_drawdown, i_co_pv_drawdown_ex_deposit, i_co_assigned_interest,
	};

	ngfun.populateUI_Data(ibx2, fln2, lcr);

	// remove previous DO/assets/RMA/etc boxes if any
	/*
	if(dorders_holder.getFellowIfAny("dorder_grid") != null) dorder_grid.setParent(null);
	if(rmas_holder.getFellowIfAny("rma_grid") != null) rmas_grid.setParent(null);

	makeLinkThingsGrid(rmas_holder,"rmas_grid","rma_rows",rma_colws,rma_colls,"background:#97b83a");
	showLC_RMA_recs(glob_selected_lc,rma_rows); // show RMA recs if any

	makeLinkThingsGrid(dorders_holder,"dorder_grid","dorder_rows",do_colws,do_colls,"background:#97b83a");
	showLC_DO_recs(glob_selected_lc,dorder_rows); // show DO recs if any
	*/

	showAssets(iwhat); // list assets link to this LC
	fillDocumentsList(documents_holder,LC_PREFIX,iwhat);

	// reset/hide some stuff when new LC selected - avoid brought-over from previous selection
	glob_selected_ass = glob_selected_asstag = "";
	glob_sel_assetrec = null;
	assbom_holder.setVisible(false);

	showJobNotes(JN_linkcode(),jobnotes_holder,"jobnotes_lb");
	jobnotes_div.setVisible(true);
	mainworkarea.setVisible(true);
}

Object[] lclb_hds =
{
	new listboxHeaderWidthObj("REC",true,"60px"),
	new listboxHeaderWidthObj("LC#",true,"50px"),
	new listboxHeaderWidthObj("RW#",true,"70px"),
	new listboxHeaderWidthObj("ROC#",true,"60px"),
	new listboxHeaderWidthObj("Customer",true,""),
	new listboxHeaderWidthObj("A.Qty",true,"50px"),
	new listboxHeaderWidthObj("S.Date",true,"60px"),
	new listboxHeaderWidthObj("E.Date",true,"60px"),
	new listboxHeaderWidthObj("Period",true,"60px"),
	new listboxHeaderWidthObj("Instalm",true,"60px"),
	new listboxHeaderWidthObj("Status",true,"80px"),
	new listboxHeaderWidthObj("User",true,"90px"),
	new listboxHeaderWidthObj("Ord.Type",true,""),
};

class lclbClick implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_selected_lc_li = isel;
		glob_selected_lc = lbhand.getListcellItemLabel(isel,0);
		glob_sel_lc_str = lbhand.getListcellItemLabel(isel,1);
		glob_sel_customer = lbhand.getListcellItemLabel(isel,4);
		showLCMetadata(glob_selected_lc);
		/*
		showAssets(glob_selected_lc);
		lcworkarea.setVisible(true);
		lc_metagrid.setVisible(true);
		*/
	}
}
lclcblicker = new lclbClick();
glob_commasep = "";

void listROCLC(int itype)
{
	Listbox newlb = lbhand.makeVWListbox_Width(rocs_holder, lclb_hds, "lc_lb", 10);

	if(itype == 4) // save the quoted-comma-separated things
	{
		glob_commasep = search_txt.getValue().trim();
	}

	last_list_type = itype;
	sct = kiboo.replaceSingleQuotes(search_txt.getValue().trim());
	//sdate = kiboo.getDateFromDatebox(startdate);
	//edate = kiboo.getDateFromDatebox(enddate);

	sqlstm = "select lc.origid, lc.lc_id, lc.rocno, lc.customer_name,lc.period,lc.lstartdate,lc.lenddate,lc.lstatus, lc.super_reminder, " +
	"(select count(origid) from rw_lc_equips where lc_parent=lc.origid) as aqty, lc.inst_type, lc.rwno, " + 
	"lc.order_type, lc.username from rw_lc_records lc ";

	switch(itype)
	{
		case 1 : // find LC by customer-name
			if(sct.equals("")) return;

			sqlstm += "where (lc.customer_name like '%" + sct + "%' or " +
			"lc.order_type like '%" + sct + "%' or lc.remarks like '%" + sct + "%' or " +
			"lc.rwno like '%" + sct + "%' or lc.lc_id like '%" + sct + "%') " +
			"order by lc.rwno";

			glob_commasep = "";
			break;
		case 2 : // by LC end date
			sqlstm += "where lc.lenddate between '" + sdate + "' and '" + edate + "' " +
			"and (lc.lstatus='active' or lstatus is null) " +
			"order by lc.rwno";

			glob_commasep = "";
			break;

		case 3 : // load latest 40 entered
			sqlstm = "select top 40 lc.origid, lc.lc_id, lc.rocno, lc.customer_name,lc.period,lc.lstartdate,lc.lenddate,lc.lstatus, lc.super_reminder," +
			"(select count(origid) from rw_lc_equips where lc_parent=lc.origid) as aqty, lc.inst_type, lc.rwno, " + 
			"lc.order_type, lc.username from rw_lc_records lc " +
			"order by lc.origid desc";
			glob_commasep = "";
			break;

		case 4: // list by what're found, uses sct
			search_txt.setValue("");
			sqlstm += "where lc.lc_id in (" + glob_commasep + ");";
			break;
	}
	
	lcrecs = sqlhand.gpSqlGetRows(sqlstm);
	if(lcrecs.size() == 0) return;
	newlb.setRows(22);
	newlb.setMold("paging");
	newlb.addEventListener("onSelect", lclcblicker);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "lc_id", "rwno", "rocno", "customer_name", "aqty", "lstartdate", "lenddate", "period",
	"inst_type", "lstatus", "username", "order_type" };
	for(dpi : lcrecs)
	{
		ngfun.popuListitems_Data(kabom,fl,dpi);
		sty = "";
		if(dpi.get("super_reminder")) sty = "background:#EBF531;font-weight:bold;font-size:9px";
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false",sty);
		kabom.clear();
	}
}

// Clear the main LC metaform fields
void clearLCMetaFields()
{
	Object[] flds = {
	i_lc_no, i_rwno, i_rocno, i_prev_lc, i_prev_roc, l_fc6_custid,
	customername, i_lstartdate, i_lenddate, i_period, i_rm_month, i_rm_contract, i_inst_type,
	i_qty_dt, i_qty_mt, i_qty_nb, i_qty_pt, i_qty_hs, i_qty_ms,
	i_product_name, i_order_type, i_remarks, i_assigned, i_charge_out_date, i_charge_out_period,
	i_charge_out, i_fina_ref, i_fina_amount, i_co_assigned_name, i_co_do_ref, i_co_master_lc,
	i_co_monthly_rental, i_co_instalment_count, i_co_due_date, i_co_deposit, i_co_recv_ex_deposit, i_co_recv_in_deposit,
	i_co_pv_drawdown, i_co_pv_drawdown_ex_deposit, i_co_assigned_interest, i_co_inv_to_financer, i_cust_project_id, i_batch_lc
	};

	ngfun.clearUI_Field(flds);
}


