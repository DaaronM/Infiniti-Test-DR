<%@ Page Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" Inherits="ManagementPortal.Tenants" Codebehind="Tenants.aspx.vb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <asp:ScriptManager runat="server" ID="ScriptManager1" />
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button id="btnNew" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, NewTenant %>" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnShowHideTenants" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, ShowDeactivated %>" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnEmailData" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, EmailTenants %>" />
        </div>
        <div class="body" runat="server">
            <asp:UpdatePanel ID="pnlTenants" runat="server">
                <ContentTemplate>
                    <asp:GridView ID="grdTenants" runat="server" AutoGenerateColumns="False"
                        DataSourceID="TenantDataSource" AlternatingRowStyle-CssClass="cell-normal" RowStyle-CssClass="cell-normal" 
                        CssClass="grd" cellspacing="1" cellpadding="3" GridLines="Both"
                        AllowPaging="false" AllowSorting="True" Width="100%" PageSize="100" EnableViewState="false" 
                        SortedAscendingHeaderStyle-CssClass="sortasc" SortedDescendingHeaderStyle-CssClass="sortdesc">
                        <Columns>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, TenantName%>" SortExpression="Name">
                                <ItemTemplate>
                                    <%# If(Eval("Disabled") = 0,
                                               "<a href='TenantEdit.aspx?ID=" & Eval("BusinessUnitGUID").ToString() & "'>" & Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Name")) & "</a>",
                                               "<a href='TenantEdit.aspx?ID=" & Eval("BusinessUnitGUID").ToString() & "'>" & "<strike>" & Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Name")) & "</strike>" & "</a>")
                                    %>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, ExpiryDate%>" SortExpression="LicenseExpiryDate">
                                <ItemTemplate>
                                    <%# If(Date.Compare(DateTime.UtcNow, Eval("LicenseExpiryDate")) > 0, "<span style=""color:red"">" & Eval("LicenseExpiryDate") & "</span>", "<span>" & Eval("LicenseExpiryDate") & "</span>") 
                                    %>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:BoundField DataField="UserCount" SortExpression="UserCount" HeaderText="<%$Resources:Strings, UserCount%>" />
                            <asp:BoundField DataField="AnonymousProjectCount" SortExpression="AnonymousProjectCount" HeaderText="<%$Resources:Strings, AnonymousProjectCount%>" />
                            <asp:BoundField DataField="InternalProjectCount" SortExpression="InternalProjectCount" HeaderText="<%$Resources:Strings, InternalProjectCount%>" />
                            <asp:BoundField DataField="TenantType" SortExpression="TenantType" HeaderText="<%$Resources:Strings, TenantType%>" />
                        </Columns>
                        <RowStyle CssClass="cell-normal" />
                        <AlternatingRowStyle CssClass="cell-normal" />
                        <EmptyDataTemplate><%=Resources.Strings.NoTenants%></EmptyDataTemplate>
                    </asp:GridView>
                </ContentTemplate>
            </asp:UpdatePanel>
        </div>

        <asp:ObjectDataSource ID="TenantDataSource" runat="server" SelectMethod="BindTenants"
                    TypeName="ManagementPortal.TenantController" SortParameterName="sortExpression">
                    <SelectParameters>
                        <asp:ControlParameter DefaultValue="" Name="unUsedStatus" PropertyName="Text" ControlID="btnShowHideTenants" Type="String" />
                    </SelectParameters>
            </asp:ObjectDataSource>
    </div>
</asp:Content>

