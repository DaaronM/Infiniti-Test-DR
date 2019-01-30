<%@ Page Title="" Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.DefinitionDetails" Codebehind="DefinitionDetails.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnEdit" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Edit %>" />
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <Controls:DeleteButton ID="btnDelete" runat="server" CssClass="toolbtn" CausesValidation="False">
            </Controls:DeleteButton>
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td style="width:100px">
                        <span class="m">*</span><asp:Label ID="lblName" runat="server" Text="<%$Resources:Strings, Name %>"
                            AssociatedControlID="txtName"></asp:Label></td>
                    <td><asp:TextBox ID="txtName" MaxLength="200" CssClass="fld" runat="server" /><asp:RequiredFieldValidator
                            ID="valName" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtName" CssClass="wrn"></asp:RequiredFieldValidator></td>
                </tr>
                <tr>
                    <td><label for="chkEnabled"><%=Resources.Strings.Enabled%></label></td><td><asp:Checkbox ID="chkEnabled" runat="server" ClientIDMode="Static" /></td>
                </tr>
                <tr>
                    <td><%=Resources.Strings.DateCreated%></td><td><asp:Literal ID="litDateCreated" runat="server" /></td>
                </tr>
                <tr>
                    <td><%=Resources.Strings.DateModified%></td><td><asp:Literal ID="litDateModified" runat="server" /></td>
                </tr>
                <tr>
                    <td><%=Resources.Strings.NextRunDate%></td><td><asp:Literal ID="litNextRunDate" runat="server" /></td>
                </tr>
                <tr>
                    <td><%=Resources.Strings.Owner%></td><td><asp:Literal ID="litOwner" runat="server" /></td>
                </tr>
            </table>
            <table width="100%" id="HistoryBreak" runat="server" role="presentation">
                <tr>
                    <td>
                        <strong><%=Resources.Strings.History %></strong>
                    </td>
                    <td width="100%">
                        <hr />
                    </td>
                </tr>
            </table>
            <Controls:PagedGridView ID="grdQueue" runat="server" Width="100%" DataSourceID="odsQueue" AutoGenerateColumns="False" EnableViewState="False" PageSize="50" CssClass="grd">
                <Columns>
                    <asp:BoundField DataField="UserName" />
                    <asp:BoundField DataField="ProjectName" />
                    <asp:TemplateField>
                        <ItemTemplate>
                            <%#Infiniti.MvcControllers.UserSettings.FormatLocalDate(CType(Eval("DateStartedUtc"), DateTime))%>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="Status" />
                    <asp:TemplateField>
                        <ItemTemplate>
                            <asp:HyperLink ID="lnkMessages" runat="server" Text="<%$Resources:Strings, View %>" NavigateUrl="~/ViewMessages.aspx?JobGuid=" />
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                <EmptyDataTemplate><asp:Literal ID="litEmpty" runat="server" Text="<%$Resources:Strings, NoHistory %>" /></EmptyDataTemplate>
            </Controls:PagedGridView>
            <asp:ObjectDataSource ID="odsQueue" runat="server" SelectMethod="GetQueue" TypeName="Intelledox.Controller.JobController">
                <SelectParameters>
                    <asp:QueryStringParameter Name="jobDefinitionId" Type="Object" QueryStringField="JobDefinitionId" />
                </SelectParameters>
            </asp:ObjectDataSource>
        </div>
    </div>
</asp:Content>

