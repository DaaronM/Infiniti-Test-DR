<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Definitions" Codebehind="Definitions.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<%@ Register TagPrefix="uc1" TagName="ctlDate" Src="Controls/ctlDate.ascx" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="toolbar">
                    <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
                </div>
                <div class="searcharea">
                    <table role="presentation">
                        <tr>
                            <td>
                                <asp:Label ID="litName" runat="server" Text="<%$Resources:Strings, Name %>" AssociatedControlID="txtName"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtName" runat="server"></asp:TextBox>
                            </td>
                            <td></td>
                            <td></td>
                            <td></td>
                        </tr>
                        <tr>
                            <td style="width:125px">
                                <label for="txtFrom"><%:Resources.Strings.DateCreated%> <%:Resources.Strings.From%></label>
                            </td>
                            <td>
                                <uc1:ctlDate ID="dteFrom" TextboxId="txtFrom" runat="server" ClientIDMode="Static"></uc1:ctlDate>
                            </td>
                            <td>
                                <label for="txtTo"><%:Resources.Strings.ToResource%></label>
                            </td>
                            <td>
                                <uc1:ctlDate ID="dteTo" TextboxId="txtTo" runat="server" ClientIDMode="Static"></uc1:ctlDate>
                            </td>
                            <td></td>
                        </tr>
                        <tr>
                            <td style="width:125px">
                                <label for="txtNextFrom"><%:Resources.Strings.NextRunDate%> <%:Resources.Strings.From%></label>
                            </td>
                            <td>
                                <uc1:ctlDate ID="dteNextFrom" TextboxId="txtNextFrom" runat="server" ClientIDMode="Static"></uc1:ctlDate>
                            </td>
                            <td>
                                <label for="txtNextTo"><%:Resources.Strings.ToResource%></label>
                            </td>
                            <td>
                                <uc1:ctlDate ID="dteNextTo" TextboxId="txtNextTo" runat="server" ClientIDMode="Static"></uc1:ctlDate>
                            </td>                            
                            <td>
                                <asp:Button ID="btnSearch" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Search %>" />
                            </td>
                        </tr>
                    </table>
                </div>
                <div class="body">
                    <Controls:PagedGridView ID="grdDefinitions" runat="server" Width="100%" DataSourceID="odsDefs" AutoGenerateColumns="False" 
                            EnableViewState="False" PageSize="50" CssClass="grd" AllowSorting="true">
                        <Columns>
                            <asp:TemplateField SortExpression="Name">
                                <ItemTemplate>
                                    <%#If(Not Eval("IsEnabled"), "<strike>", "")%>
                                    <a href="DefinitionDetails.aspx?jobDefinitionId=<%# Eval("JobDefinitionId") %>"><%#Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Name")) %></a>
                                    <%#If(Not Eval("IsEnabled"), "</strike>", "")%>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%# GetUserName(Eval("OwnerGuid")) %>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField SortExpression="DateCreatedUtc">
                                <ItemTemplate>
                                    <%# Infiniti.MvcControllers.UserSettings.FormatLocalDate(CType(Eval("DateCreatedUtc"), DateTime))%>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField SortExpression="NextRunDateUtc">
                                <ItemTemplate>
                                    <%# Infiniti.MvcControllers.UserSettings.FormatLocalDate(CType(Eval("NextRunDateUtc"), DateTime))%>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                        <EmptyDataTemplate><asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoHistory %>" /></EmptyDataTemplate>
                    </Controls:PagedGridView>
                    <asp:ObjectDataSource ID="odsDefs" runat="server" SelectMethod="GetJobDefinitionsBySearch" TypeName="Intelledox.Controller.JobController" SortParameterName="sortExpression">
                        <SelectParameters>
                            <asp:Parameter Name="BusinessUnitGuid" Type="Object" />
                            <asp:ControlParameter Name="Name" ControlID="txtName" />
                            <asp:Parameter Name="DateCreatedFrom" Type="DateTime" />
                            <asp:Parameter Name="DateCreatedTo" Type="DateTime" />
                            <asp:Parameter Name="NextRunFrom" Type="DateTime" />
                            <asp:Parameter Name="NextRunTo" Type="DateTime" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>

