<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ManagementConsole" CodeBehind="ManagementConsole.aspx.vb" %>

<%@ Reference Control="~/controls/ctldate.ascx" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<%@ Register TagPrefix="uc1" TagName="ctlDate" Src="Controls/ctlDate.ascx" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>

    <script type="text/javascript">
        var selectedState = 0;

        function EnableAction(ctl, status) {
            if (selectedState == 0 || selectedState == status) {
                if (status == <%=Intelledox.Model.JobStatus.Queued %>) {
                    document.getElementById('<%=btnPause.ClientId %>').value = ' + <%=Resources.Strings.Pause %> + ';
                }
                else {
                    document.getElementById('<%=btnPause.ClientId %>').value = ' + <%=Resources.Strings.ResumeString %> + ';
                }
                selectedState = status;
                EnableControls();
            }
            else {
                alert('<%=Resources.Strings.SelectSameType %>');
                ctl.checked = false;
            }
        }

        function EnableControls() {
            var enable = false;
            var checkboxes = document.getElementsByName('chkSelect');

            for (i = 0; i < checkboxes.length; i++) {
                if (checkboxes[i].checked) {
                    enable = true;
                }
            }

            document.getElementById('<%=btnPause.ClientId %>').disabled = !enable;
            document.getElementById('<%=btnCancel.ClientId %>').disabled = !enable;

            if (!enable) {
                selectedState = 0;
            }
        }
    </script>

    <div id="contentinner" class="base1">
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="toolbar">
                    <asp:Button ID="btnDefinitions" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Definitions %>" CausesValidation="false" />
                    <span class="tooldiv"></span>
                    <asp:Button ID="btnPauseAll" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, PauseAll %>" CausesValidation="true" />
                    <asp:Button ID="btnResumeAll" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, ResumeAll %>" CausesValidation="true" />
                    <asp:Button ID="btnCancelAll" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, CancelAll %>" CausesValidation="true" />
                    <span class="tooldiv"></span>
                    <asp:Button ID="btnPause" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Pause %>" CausesValidation="false" Enabled="false" />
                    <asp:Button ID="btnCancel" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Cancel %>" CausesValidation="false" Enabled="false" />
                </div>
                <div class="searcharea">
                    <table role="presentation">
                        <tr>
                            <td>
                                <label for="txtFrom"><%:Resources.Strings.From%></label>
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
                            <td colspan="4">
                                <asp:CustomValidator ID="valCompareDates" runat="server" CssClass="wrn" OnServerValidate="valCompareDates_ServerValidate"></asp:CustomValidator>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="litStatus" runat="server" Text="<%$Resources:Strings, Status %>" AssociatedControlID="lstStatus" />
                            </td>
                            <td>
                                <asp:DropDownList ID="lstStatus" runat="server">
                                </asp:DropDownList>
                            </td>
                        
                            <td></td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="litIncludeScheduled" runat="server" Text="<%$Resources:Strings, IncludeScheduled %>" AssociatedControlID="chkIncludeScheduled" />
                            </td>
                            <td>
                                <asp:CheckBox ID="chkIncludeScheduled" runat="server"></asp:CheckBox>

                            </td>
                                <td></td>
                            <td></td>
                            <td>
                                <asp:Button ID="btnSearch" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Search %>" CausesValidation="true" />
                            </td>
                        </tr>
                    </table>
                </div>
                <div class="body">
                    <Controls:PagedGridView ID="grdQueue" runat="server" Width="100%" DataSourceID="odsQueue" AutoGenerateColumns="False" EnableViewState="False" PageSize="50" CssClass="grd">
                        <Columns>
                            <asp:TemplateField ItemStyle-Width="1px">
                                <ItemTemplate>
                                    <input type="checkbox" name="chkSelect" value="<%# Eval("JobId") %>" <%#IIF(Eval("Status")= 1 Or Eval("Status")=3, "", "disabled") %> onclick="Javascript: EnableAction(this, '<%#CInt(Eval("Status")) %>')"></input>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%#:GetUserName(Eval("UserGuid"), Eval("UserName"), Eval("Scheduled"))%>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:BoundField DataField="ProjectName" />
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%#Infiniti.MvcControllers.UserSettings.FormatLocalDate(CType(Eval("DateStartedUtc"), DateTime))%>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <%#GetStatusString(Eval("Status"))%>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField>
                                <ItemTemplate>
                                    <asp:HyperLink ID="lnkMessages" runat="server" Text="<%$Resources:Strings, View %>" NavigateUrl="~/ViewMessages.aspx?JobGuid=" />
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                        <EmptyDataTemplate>
                            <asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoHistory %>" /></EmptyDataTemplate>
                    </Controls:PagedGridView>
                    <asp:ObjectDataSource ID="odsQueue" runat="server" SelectMethod="GetQueue" TypeName="Intelledox.Controller.JobController">
                        <SelectParameters>
                            <asp:Parameter Name="BusinessUnitGuid" Type="Object" />
                            <asp:Parameter Name="StartDate" Type="DateTime" />
                            <asp:Parameter Name="FinishDate" Type="DateTime" />
                            <asp:ControlParameter ControlID="lstStatus" PropertyName="SelectedValue" Name="CurrentStatus" Type="Int32" />
                            <asp:ControlParameter ControlID="chkIncludeScheduled" PropertyName="Checked" Name="Scheduled" Type="Boolean" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>
